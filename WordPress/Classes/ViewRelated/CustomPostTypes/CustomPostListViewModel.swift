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
    let filter: CustomPostListFilter
    weak var presentingViewController: UIViewController?

    private var collection: PostMetadataCollectionWithEditContext
    private var isBatchSyncing = false

    @Published private(set) var items: [CustomPostCollectionItem] = []
    @Published private(set) var listInfo: ListInfo?
    @Published private(set) var indentationMap: IndentationMap = [:]
    @Published private var error: Error?
    @Published var postToDelete: AnyPostWithEditContext?
    @Published var postToTrash: AnyPostWithEditContext?
    @Published var progressHUDState: ProgressHUDState = .idle

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
                perPage: 20
            )
    }

    func refresh() async {
        if shouldDisplayHierarchy {
            await fetchAllPages()
        } else {
            await fetchWithPagination()
        }
    }

    func loadNextPage() async throws {
        // All pages are already loaded by refresh() for hierarchical posts.
        guard !shouldDisplayHierarchy else { return }

        if let listInfo, listInfo.isSyncing || !listInfo.hasMorePages {
            return
        }

        if listInfo?.currentPage == nil {
            _ = try await collection.refresh()
        } else {
            _ = try await collection.loadNextPage()
        }
    }

    func loadCachedItems() async {
        let listInfo = collection.listInfo()

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

    /// Fetches all pages before updating the UI, so the hierarchy tree is
    /// built once from the complete dataset.
    private func fetchAllPages() async {
        isBatchSyncing = true
        defer { isBatchSyncing = false }

        do {
            _ = try await collection.refresh()

            while !Task.isCancelled {
                guard let listInfo = collection.listInfo(), listInfo.hasMorePages, !listInfo.isSyncing else {
                    break
                }
                _ = try await collection.loadNextPage()
            }

            await loadCachedItems()
        } catch {
            Loggers.app.error("Failed to refresh all pages: \(error)")
            self.show(error: error)
        }
    }

    private var shouldDisplayHierarchy: Bool {
        isHierarchical && (filter.statuses.contains(.publish) || filter.statuses.contains(.custom("any")))
    }

    private func updateItems(from metadataItems: [PostMetadataCollectionItem]) {
        let items = metadataItems.map { CustomPostCollectionItem(item: $0, blog: blog, primaryStatus: filter.primaryStatus) }

        guard shouldDisplayHierarchy else {
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
            service: service.posts()
        )
        PublishPostViewController.show(
            editorService: editorService,
            blog: blog,
            from: vc,
            completion: { _ in }
        )
    }

    func moveToDraft(_ post: AnyPostWithEditContext) async {
        var params = PostUpdateParams(meta: nil)
        params.status = .draft
        await updatePost(post, params: params)
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
                service: service.posts()
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
        progressHUDState = .running
        do {
            _ = try await service.posts().trashPost(endpointType: endpoint, postId: post.id)
            progressHUDState = .success
        } catch {
            Loggers.app.error("Failed to trash post: \(error)")
            progressHUDState = .failure(error.localizedDescription)
        }
    }

    func deletePost(_ post: AnyPostWithEditContext) async {
        progressHUDState = .running
        do {
            _ = try await service.posts().deletePostPermanently(endpointType: endpoint, postId: post.id)
            progressHUDState = .success
        } catch {
            Loggers.app.error("Failed to delete post: \(error)")
            progressHUDState = .failure(error.localizedDescription)
        }
    }

    private func updatePost(_ post: AnyPostWithEditContext, params: PostUpdateParams) async {
        progressHUDState = .running
        do {
            _ = try await service.posts().updatePost(endpointType: endpoint, postId: post.id, params: params)
            progressHUDState = .success
        } catch {
            Loggers.app.error("Failed to update post: \(error)")
            progressHUDState = .failure(error.localizedDescription)
        }
    }

    private func show(error: Error) {
        // TODO: Ignore error https://github.com/Automattic/wordpress-rs/pull/1227
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
    let title: String?
    let content: String?
    let authorName: String?
    let status: PostStatus
    let sticky: Bool
    let featuredMedia: MediaId?
    let primaryStatus: PostStatus

    init(
        date: Date,
        title: String?,
        content: String?,
        authorName: String? = nil,
        status: PostStatus = .publish,
        sticky: Bool = false,
        featuredMedia: MediaId? = nil,
        primaryStatus: PostStatus = .publish
    ) {
        self.date = date
        self.title = title
        self.content = content
        self.authorName = authorName
        self.status = status
        self.sticky = sticky
        self.featuredMedia = featuredMedia
        self.primaryStatus = primaryStatus
    }

    init(_ entity: AnyPostWithEditContext, blog: Blog, contentLimit: Int = 100, primaryStatus: PostStatus = .publish) {
        self.date = entity.dateGmt
        self.title = entity.title?.raw
        let contentPreview = GutenbergExcerptGenerator
            .firstParagraph(
                from: entity.content.rendered,
                maxLength: contentLimit
            )
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
        if status == .future {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
        return date.formatted(date: .abbreviated, time: .omitted)
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
        case .custom(let value):
            return value
        }
    }
}

// TODO: Decouple the "display item" from the internall states of the `PostMetadataCollectionItem`
enum CustomPostCollectionItem: Identifiable, Equatable {
    case ready(id: Int64, post: CustomPostCollectionDisplayPost, fullPost: AnyPostWithEditContext)
    case stale(id: Int64, post: CustomPostCollectionDisplayPost)
    case refreshing(id: Int64, post: CustomPostCollectionDisplayPost)
    case fetching(id: Int64)
    case missing(id: Int64)
    case error(id: Int64, message: String)
    case errorWithData(id: Int64, message: String, post: CustomPostCollectionDisplayPost)

    var id: Int64 {
        switch self {
        case .ready(let id, _, _),
             .stale(let id, _),
             .refreshing(let id, _),
             .fetching(let id),
             .missing(let id),
             .error(let id, _),
             .errorWithData(let id, _, _):
            return id
        }
    }

    init(item: PostMetadataCollectionItem, blog: Blog, primaryStatus: PostStatus = .publish) {
        let id = item.id

        switch item.state {
        case .fresh(let entity):
            self = .ready(id: id, post: CustomPostCollectionDisplayPost(entity.data, blog: blog, primaryStatus: primaryStatus), fullPost: entity.data)

        case .stale(let entity):
            self = .stale(id: id, post: CustomPostCollectionDisplayPost(entity.data, blog: blog, primaryStatus: primaryStatus))

        case .fetchingWithData(let entity):
            self = .refreshing(id: id, post: CustomPostCollectionDisplayPost(entity.data, blog: blog, primaryStatus: primaryStatus))

        case .fetching:
            self = .fetching(id: id)

        case .missing:
            self = .missing(id: id)

        case .failed(let error):
            self = .error(id: id, message: error)

        case .failedWithData(let error, let entity):
            self = .errorWithData(id: id, message: error, post: CustomPostCollectionDisplayPost(entity.data, blog: blog, contentLimit: 50, primaryStatus: primaryStatus))
        }
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
