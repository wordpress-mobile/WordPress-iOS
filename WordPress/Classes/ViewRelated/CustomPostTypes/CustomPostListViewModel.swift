import Foundation
import SwiftUI
import UIKit
import WordPressAPI
import WordPressAPIInternal
import WordPressCore
import WordPressData
import WordPressShared

@MainActor
final class CustomPostListViewModel: ObservableObject {
    typealias IndentationMap = [Int64: PageTree.Entry<Int64>]

    let client: WordPressClient
    private let service: WpService
    private let endpoint: PostEndpointType
    private let details: PostTypeDetailsWithEditContext
    let blog: Blog
    private let isHierarchical: Bool
    private(set) var filter: CustomPostListFilter
    weak var presentingViewController: UIViewController?

    private var collection: PostMetadataCollectionWithEditContext
    private var homepageSetting: HomepageSetting?
    private var isBatchSyncing = false
    // Whether we should show the content in a hierarchy view.
    // true if the number of cached items or the total items return by the API
    // is less than a threshold, where the app can fetch all content relative quickly.
    private var shouldShowHierarchy = false
    @Published private(set) var items: [CustomPostCollectionItem] = []
    @Published private(set) var listInfo: ListInfo?
    @Published private(set) var indentationMap: IndentationMap = [:]
    @Published private var error: Error?
    @Published var postToDelete: AnyPostWithEditContext?
    @Published var postToTrash: AnyPostWithEditContext?
    /// Post IDs with in-flight API operations (delete, trash, move-to-draft).
    /// The view uses this set to dim rows, show spinners, and disable interaction.
    @Published private(set) var pendingPostIDs: Set<Int64> = []

    var shouldDisplayEmptyView: Bool {
        items.isEmpty && listInfo?.isSyncing == false
    }

    var shouldDisplayInitialLoading: Bool {
        items.isEmpty && listInfo?.isSyncing == true
    }

    var postService: WordPressAPIInternal.PostService {
        service.posts()
    }

    func errorToDisplay() -> Error? {
        items.isEmpty ? error : nil
    }

    init(
        client: WordPressClient,
        service: WpService,
        details: PostTypeDetailsWithEditContext,
        filter: CustomPostListFilter,
        blog: Blog,
        presentingViewController: UIViewController? = nil
    ) {
        self.client = client
        self.service = service
        self.endpoint = details.toPostEndpointType()
        self.details = details
        self.blog = blog
        self.isHierarchical = details.hierarchical
        self.filter = filter
        self.presentingViewController = presentingViewController

        collection = service
            .posts()
            .createPostMetadataCollectionWithEditContext(
                endpointType: details.toPostEndpointType(),
                filter: filter.asPostListFilter(),
                perPage: 100
            )
    }

    func pullToRefresh() async {
        await refresh(pullToRefresh: true)
    }

    func updateAuthorFilter(_ author: [UserId]) {
        guard filter.author != author else { return }

        withAnimation {
            filter.author = author
            collection = service
                .posts()
                .createPostMetadataCollectionWithEditContext(
                    endpointType: endpoint,
                    filter: filter.asPostListFilter(),
                    perPage: 100
                )
            items = []
            listInfo = nil
        }
    }

    func refresh() async {
        await refresh(pullToRefresh: false)
    }

    private func refresh(pullToRefresh: Bool) async {
        await fetchHomepageSettingsIfNeeded()

        if !pullToRefresh {
            await loadCachedItems()
        }

        if shouldAttemptDisplayHierarchy {
            await fetchAllPagesIfBelowThreshold()
        } else {
            await fetchWithPagination()
        }
    }

    func loadNextPage() async throws {
        // All pages are already loaded by refresh() for hierarchical posts.
        guard !isBatchSyncing else { return }

        if let listInfo, listInfo.isSyncing || !listInfo.hasMorePages {
            return
        }

        if listInfo?.currentPage == nil {
            _ = try await collection.refresh()
        } else {
            _ = try await collection.loadNextPage()
        }
    }

    private func loadCachedItems() async {
        let listInfo = collection.listInfo()

        if let totalItems = listInfo?.totalItems, totalItems <= Constants.hierarchyPageCountThreshold {
            shouldShowHierarchy = true
        }

        do {
            let metadataItems = try await collection.loadItems()
            if self.listInfo != listInfo {
                self.listInfo = listInfo
            }
            updateItems(from: metadataItems)
        } catch {
            Loggers.app.error("Failed to load cached items: \(error)")
        }
    }

    func handleDataChanges() async {
        let batches = await client.cache.databaseUpdatesPublisher()
            .filter { [weak collection] in collection?.isRelevantUpdate(hook: $0) == true }
            .collect(.byTime(DispatchQueue.main, .milliseconds(50)))
            .values
        for await batch in batches {
            // When fetching all page to display hierarchical view, the post list is updated on one go after the
            // fetching is completed. In that scenario, we should skip the paginationed UI update.
            guard !isBatchSyncing else { continue }

            Loggers.app.info("\(batch.count) updates received from WpApiCache")

            #if DEBUG
            for hook in batch {
                Loggers.app.debug("  |- \(hook.action) to \(hook.table) at row \(hook.rowId)")
            }
            #endif

            let listInfo = collection.listInfo()

            Loggers.app.info("List info: \(String(describing: listInfo))")

            do {
                let metadataItems = try await collection.loadItems()
                withAnimation {
                    if self.listInfo != listInfo {
                        self.listInfo = listInfo
                    }
                    updateItems(from: metadataItems)
                }
            } catch {
                Loggers.app.error("Failed to get collection items: \(error)")
            }
        }
    }

    // MARK: - Loading Strategies

    /// Fetches the first page and lets `handleDataChanges` update the UI
    /// incrementally as each page loads.
    private func fetchWithPagination() async {
        do {
            _ = try await collection.refresh()
        } catch {
            Loggers.app.error("Failed to refresh posts: \(error)")
            self.show(error: error)
        }
    }

    /// Fetches the first page to determine total count. If below the
    /// threshold, fetches remaining pages and builds the hierarchy tree.
    /// Otherwise, stays in flat paginated mode.
    private func fetchAllPagesIfBelowThreshold() async {
        do {
            _ = try await collection.refresh()
        } catch {
            DDLogError("Failed to refresh pages: \(error)")
            self.show(error: error)
            return
        }

        // Load rest of the pages if total post count is less than the threshold
        let totalItems = collection.listInfo()?.totalItems ?? Int64.max
        guard totalItems <= Constants.hierarchyPageCountThreshold else {
            return
        }

        shouldShowHierarchy = true

        isBatchSyncing = true
        defer { isBatchSyncing = false }

        do {
            while !Task.isCancelled {
                guard let listInfo = collection.listInfo(), listInfo.hasMorePages, !listInfo.isSyncing else {
                    break
                }
                _ = try await collection.loadNextPage()
            }

            await loadCachedItems()
        } catch {
            Loggers.app.error("Failed to refresh all pages for hierarchy: \(error)")
            self.show(error: error)
        }
    }

    private var shouldAttemptDisplayHierarchy: Bool {
        isHierarchical && (filter.statuses.contains(.publish) || filter.statuses.contains(.any))
    }

    private func updateItems(from metadataItems: [PostMetadataCollectionItem]) {
        var items = metadataItems.map {
            CustomPostCollectionItem(item: $0, blog: blog, primaryStatus: filter.primaryStatus)
        }

        if endpoint == .pages,
           case .staticPage(let homepagePageID) = homepageSetting,
           filter.statuses.contains(.publish) || filter.statuses.contains(.custom("any")) {
            items.markHomepage(id: homepagePageID)
        }

        guard shouldShowHierarchy else {
            indentationMap = [:]
            self.items = items
            return
        }

        // Use metadata items for hierarchy data, since parent/menuOrder are
        // available from list metadata regardless of the item's fetch state.
        let posts = metadataItems.map { item in
            HierarchyInput(postId: item.id, parentPostId: item.parent ?? 0, order: Int64(item.menuOrder ?? 0))
        }

        let entries = PageTree.buildHierarchy(from: posts)
        let itemMap = Dictionary(uniqueKeysWithValues: items.compactMap { item -> (Int64, CustomPostCollectionItem)? in
            return (item.id, item)
        })

        indentationMap = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })
        self.items = entries.compactMap { itemMap[$0.id] }
    }

    // MARK: - Post Actions

    func confirmDelete(_ post: AnyPostWithEditContext) {
        postToDelete = post
    }

    func confirmTrash(_ post: AnyPostWithEditContext) {
        postToTrash = post
    }

    func publishPost(_ post: AnyPostWithEditContext) {
        guard let vc = presentingViewController else { return }

        let editorService = CustomPostEditorService(
            blog: blog,
            post: post,
            details: details,
            client: client,
            wpService: service
        )
        PublishPostViewController.show(
            editorService: editorService,
            blog: blog,
            from: vc,
            completion: { _ in }
        )
    }

    func moveToDraft(_ post: AnyPostWithEditContext) async {
        pendingPostIDs.insert(post.id)
        defer { pendingPostIDs.remove(post.id) }

        do {
            var params = PostUpdateParams(meta: nil)
            params.status = .draft
            _ = try await service.posts().updatePost(endpointType: endpoint, postId: post.id, params: params)
        } catch {
            Loggers.app.error("Failed to move post to draft: \(error)")
            Notice(error: error).post()
        }
    }

    func viewPost(_ post: AnyPostWithEditContext) {
        guard let url = URL(string: post.link) else { return }
        UIApplication.shared.open(url)
    }

    func navigationMenuItems(for post: AnyPostWithEditContext) -> [PostMenuNavigation] {
        var items: [PostMenuNavigation] = []
        if let nav = menuNavigation(forBlaze: post) {
            items.append(nav)
        }
        if let nav = menuNavigation(forStats: post) {
            items.append(nav)
        }
        if let nav = menuNavigation(forComments: post) {
            items.append(nav)
        }
        if post.status != .trash {
            items.append(.settings(post: post))
        }
        return items
    }

    func handleMenuNavigation(_ navigation: PostMenuNavigation) {
        guard let vc = presentingViewController else { return }

        switch navigation {
        case .stats(let post):
            if FeatureFlag.newStats.enabled {
                let statsVC = PostStatsViewController(
                    postID: Int(post.id),
                    postTitle: post.title?.raw ?? "",
                    postURL: URL(string: post.link),
                    postDate: post.dateGmt,
                    blog: blog
                )
                let navController = UINavigationController(rootViewController: statsVC)
                navController.modalPresentationStyle = .pageSheet
                vc.present(navController, animated: true)
            } else {
                let statsVC = PostStatsTableViewController.withJPBannerForBlog(
                    postID: Int(post.id),
                    postTitle: post.title?.raw,
                    postURL: URL(string: post.link)
                )
                vc.navigationController?.pushViewController(statsVC, animated: true)
            }

        case .comments(let post, let siteID):
            let commentsVC = ReaderCommentsViewController(
                postID: NSNumber(value: post.id),
                siteID: siteID
            )
            vc.navigationController?.pushViewController(commentsVC, animated: true)

        case .blaze(let post):
            BlazeFlowCoordinator.presentBlazeWebFlow(
                in: vc,
                source: .postsList,
                blog: blog,
                postID: NSNumber(value: post.id)
            )

        case .settings(let post):
            let editorService = CustomPostEditorService(
                blog: blog,
                post: post,
                details: details,
                client: client,
                wpService: service
            )
            let viewModel = CustomPostSettingsViewModel(editorService: editorService, blog: blog, isStandalone: true)
            let settingsVC = PostSettingsViewController(viewModel: viewModel)
            let nav = UINavigationController(rootViewController: settingsVC)
            vc.present(nav, animated: true)
        }
    }

    func menuNavigation(forBlaze post: AnyPostWithEditContext) -> PostMenuNavigation? {
        guard endpoint == .posts
                && BlazeHelper.isBlazeFlagEnabled() && blog.canBlaze
                && post.status == .publish && (post.password ?? "") == "" else { return nil }
        return .blaze(post: post)
    }

    func menuNavigation(forStats post: AnyPostWithEditContext) -> PostMenuNavigation? {
        guard endpoint == .posts
                && blog.supports(.stats) && post.status == .publish else { return nil }
        return .stats(post: post)
    }

    func menuNavigation(forComments post: AnyPostWithEditContext) -> PostMenuNavigation? {
        guard details.supports.supports(feature: .comments)
                && post.status == .publish, let siteID = blog.dotComID else { return nil }
        return .comments(post: post, siteID: siteID)
    }

    func trashPost(_ post: AnyPostWithEditContext) async {
        pendingPostIDs.insert(post.id)
        defer { pendingPostIDs.remove(post.id) }

        do {
            _ = try await service.posts().trashPost(endpointType: endpoint, postId: post.id)
        } catch {
            Loggers.app.error("Failed to trash post: \(error)")
            Notice(error: error).post()
        }
    }

    func deletePost(_ post: AnyPostWithEditContext) async {
        pendingPostIDs.insert(post.id)
        defer { pendingPostIDs.remove(post.id) }

        do {
            _ = try await service.posts().deletePostPermanently(endpointType: endpoint, postId: post.id)
        } catch {
            Loggers.app.error("Failed to delete post: \(error)")
            Notice(error: error).post()
        }
    }

    /// Fetches homepage settings using the cached site settings from
    /// `WordPressClient` when the endpoint is `.pages` and the setting
    /// has not been resolved yet.
    private func fetchHomepageSettingsIfNeeded() async {
        guard endpoint == .pages, homepageSetting == nil else { return }

        do {
            let settings = try await client.fetchSiteSettings()
            if settings.showOnFront == "page", settings.pageOnFront > 0 {
                homepageSetting = .staticPage(id: Int64(settings.pageOnFront))
            } else {
                homepageSetting = .latestPosts
            }
        } catch {
            Loggers.app.error("Failed to fetch site settings for homepage detection: \(error)")
        }
    }

    private func show(error: Error) {
        // This particular error should be ignored.
        if case FetchError.StaleLoadMore = error {
            return
        }

        self.error = error

        if !items.isEmpty {
            // Show an error notice, on top of the list content.
            Notice(error: error).post()
        }
    }
}

extension CustomPostListViewModel {

    enum PostMenuNavigation: Identifiable {
        case stats(post: AnyPostWithEditContext)
        case comments(post: AnyPostWithEditContext, siteID: NSNumber)
        case blaze(post: AnyPostWithEditContext)
        case settings(post: AnyPostWithEditContext)

        var id: String {
            label
        }

        var label: String {
            switch self {
            case .blaze: return Strings.blaze
            case .stats: return Strings.stats
            case .comments: return Strings.comments
            case .settings: return Strings.settings
            }
        }

        var systemImage: String {
            switch self {
            case .blaze: return "flame"
            case .stats: return "chart.line.uptrend.xyaxis"
            case .comments: return "bubble.right"
            case .settings: return "gearshape"
            }
        }
    }

}

struct CustomPostCollectionDisplayPost: Equatable {
    let date: Date
    let modifiedDate: Date?
    let title: String?
    let content: String?
    let authorName: String?
    let status: PostStatus
    let sticky: Bool
    let featuredMedia: MediaId?
    let primaryStatus: PostStatus
    var isHomepage: Bool

    init(
        date: Date,
        modifiedDate: Date? = nil,
        title: String?,
        content: String?,
        authorName: String? = nil,
        status: PostStatus = .publish,
        sticky: Bool = false,
        featuredMedia: MediaId? = nil,
        primaryStatus: PostStatus = .publish,
        isHomepage: Bool = false
    ) {
        self.date = date
        self.modifiedDate = modifiedDate
        self.title = title
        self.content = content
        self.authorName = authorName
        self.status = status
        self.sticky = sticky
        self.featuredMedia = featuredMedia
        self.primaryStatus = primaryStatus
        self.isHomepage = isHomepage
    }

    init(_ entity: AnyPostWithEditContext, blog: Blog, primaryStatus: PostStatus = .publish) {
        self.date = entity.dateGmt
        self.modifiedDate = entity.modifiedGmt
        self.title = entity.title?.raw
        let contentPreview = GutenbergExcerptGenerator
            .firstParagraph(from: entity.content.rendered)
            .replacingOccurrences(
                of: "[\n]{2,}",
                with: "\n",
                options: .regularExpression
            )
        self.content = contentPreview.isEmpty ? entity.excerpt?.raw : contentPreview
        if let authorId = entity.author {
            self.authorName = blog.getAuthorWith(id: NSNumber(value: authorId))?.displayName
        } else {
            self.authorName = nil
        }
        self.status = entity.status
        self.sticky = entity.sticky ?? false
        self.featuredMedia = entity.featuredMedia
        self.primaryStatus = primaryStatus
        self.isHomepage = false
    }

    /// The title to display, with a placeholder for untitled posts.
    var titleForDisplay: String {
        let trimmed = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmed.isEmpty {
            return NSLocalizedString(
                "customPostList.untitled",
                value: "(no title)",
                comment: "Placeholder title for posts without a title"
            )
        }
        return trimmed
    }

    /// The header badges string (e.g. "Jan 15, 2026 · Author Name") matching
    /// the regular posts list. Combines the formatted date and author name.
    var headerBadges: String {
        var badges = [dateForDisplay]
        if let authorName, !authorName.isEmpty {
            badges.append(authorName)
        }
        return badges.joined(separator: " · ")
    }

    private var dateForDisplay: String {
        let string: String
        switch status {
        case .future:
            string = date.mediumStringWithTime()
        case .publish, .private:
            string = date.toMediumString()
        case .trash:
            string = (modifiedDate ?? date).toMediumString()
        default:
            string = (modifiedDate ?? date).toMediumString()
        }
        return string.capitalized(with: .current)
    }

    /// Combined status badges (e.g. "Private · Sticky") matching the regular
    /// posts list. Returns nil when there is nothing to display.
    var statusBadges: String? {
        var badges: [String] = []

        // Show a status badge when the post's status isn't one of the filter's
        // statuses, since it would be redundant otherwise.
        let showStatus = status != primaryStatus
        if showStatus {
            badges.append(status.localizedLabel())
        }
        if sticky {
            badges.append(Strings.sticky)
        }

        return badges.isEmpty ? nil : badges.joined(separator: " · ")
    }

    var statusColor: Color {
        if status == .trash {
            return .red
        }
        return .secondary
    }

    static let placeholder = CustomPostCollectionDisplayPost(
        date: .now,
        title: "Lorem ipsum dolor sit amet",
        content: "Lorem ipsum dolor sit amet consectetur adipiscing elit"
    )
}

extension PostStatus {
    func localizedLabel() -> String {
        switch self {
        case .publish:
            return SharedStrings.PostStatus.published
        case .draft:
            return SharedStrings.PostStatus.draft
        case .future:
            return SharedStrings.PostStatus.scheduled
        case .pending:
            return SharedStrings.PostStatus.pending
        case .private:
            return SharedStrings.PostStatus.privatePost
        case .trash:
            return SharedStrings.PostStatus.trash
        case .any:
            // This branch should never happen, since "any" is magic filter and no post would have this status.
            return SharedStrings.PostStatus.any
        case .custom(let value):
            return value
        }
    }
}

struct CustomPostCollectionItem: Identifiable, Equatable {
    let id: Int64
    var post: CustomPostCollectionDisplayPost?
    var state: State

    enum State: Equatable {
        case loaded(fullPost: AnyPostWithEditContext, isUpToDate: Bool)
        case loading
        case error(message: String)
    }

    var isHomepage: Bool {
        get {
            post?.isHomepage ?? false
        }
        set {
            post?.isHomepage = newValue
        }
    }

    init(item: PostMetadataCollectionItem, blog: Blog, primaryStatus: PostStatus = .publish) {
        self.id = item.id

        switch item.state {
        case .fresh(let entity):
            self.post = CustomPostCollectionDisplayPost(entity.data, blog: blog, primaryStatus: primaryStatus)
            self.state = .loaded(fullPost: entity.data, isUpToDate: true)

        case .stale(let entity):
            self.post = CustomPostCollectionDisplayPost(entity.data, blog: blog, primaryStatus: primaryStatus)
            self.state = .loaded(fullPost: entity.data, isUpToDate: false)

        case .fetchingWithData, .fetching, .missing:
            self.post = nil
            self.state = .loading

        case .failed(let error):
            self.post = nil
            self.state = .error(message: error)

        case .failedWithData(let error, let entity):
            self.post = CustomPostCollectionDisplayPost(entity.data, blog: blog, primaryStatus: primaryStatus)
            self.state = .error(message: error)
        }
    }
}

extension Array where Element == CustomPostCollectionItem {
    /// Marks the homepage item with the `isHomepage` flag.
    mutating func markHomepage(id: Int64) {
        guard let homepageIndex = firstIndex(where: { $0.id == id }) else {
            return
        }
        self[homepageIndex].isHomepage = true
    }
}

private extension ListInfo {
    var isSyncing: Bool {
        state == .fetchingFirstPage || state == .fetchingNextPage
    }

    var hasMorePages: Bool {
        guard let currentPage, let totalPages else { return true }
        return currentPage < totalPages
    }
}

private struct HierarchyInput: HierarchicalPost {
    var id: Int64 {
        postId
    }

    var postId: Int64
    var parentPostId: Int64
    var order: Int64
}

extension AnyPostWithEditContext: HierarchicalPost {
    var postId: Int64 {
        id
    }

    var parentPostId: Int64 {
        parent ?? 0
    }

    var order: Int64 {
        Int64(menuOrder ?? 0)
    }
}

private enum Strings {
    static let sticky = NSLocalizedString(
        "customPostList.badge.sticky",
        value: "Sticky",
        comment: "Badge shown in the post list for sticky posts"
    )
    static let blaze = NSLocalizedString(
        "customPostList.action.blaze",
        value: "Promote with Blaze",
        comment: "Menu action to promote a post with Blaze"
    )
    static let stats = NSLocalizedString(
        "customPostList.action.stats",
        value: "Stats",
        comment: "Menu action to view post statistics"
    )
    static let comments = NSLocalizedString(
        "customPostList.action.comments",
        value: "Comments",
        comment: "Menu action to view post comments"
    )
    static let settings = NSLocalizedString(
        "customPostList.action.settings",
        value: "Settings",
        comment: "Menu action to open post settings"
    )
}

/// Represents the WordPress "Your homepage displays" setting.
private enum HomepageSetting {
    case latestPosts
    case staticPage(id: Int64)
}

private enum Constants {
    static let hierarchyPageCountThreshold: Int64 = 200
}
