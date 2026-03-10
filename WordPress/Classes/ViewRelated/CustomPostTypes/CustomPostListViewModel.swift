import Foundation
import SwiftUI
import WordPressAPI
import WordPressAPIInternal
import WordPressCore
import WordPressData
import WordPressShared

@MainActor
final class CustomPostListViewModel: ObservableObject {
    typealias IndentationMap = [Int64: PageTree.Entry<Int64>]

    private let client: WordPressClient
    private let blog: Blog
    private let isHierarchical: Bool
    let filter: CustomPostListFilter

    private var collection: PostMetadataCollectionWithEditContext
    private var isBatchSyncing = false

    @Published private(set) var items: [CustomPostCollectionItem] = []
    @Published private(set) var listInfo: ListInfo?
    @Published private(set) var indentationMap: IndentationMap = [:]
    @Published private var error: Error?

    var shouldDisplayEmptyView: Bool {
        items.isEmpty && listInfo?.isSyncing == false
    }

    var shouldDisplayInitialLoading: Bool {
        items.isEmpty && listInfo?.isSyncing == true
    }

    func errorToDisplay() -> Error? {
        items.isEmpty ? error : nil
    }

    init(
        client: WordPressClient,
        service: WpService,
        details: PostTypeDetailsWithEditContext,
        filter: CustomPostListFilter,
        blog: Blog
    ) {
        self.client = client
        self.blog = blog
        self.isHierarchical = details.hierarchical
        self.filter = filter

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
            DDLogError("Failed to load cached items: \(error)")
        }
    }

    func handleDataChanges() async {
        let batches = await client.cache.databaseUpdatesPublisher()
            .filter { [weak collection] in collection?.isRelevantUpdate(hook: $0) == true }
            .collect(.byTime(DispatchQueue.main, .milliseconds(50)))
            .values
        for await batch in batches {
            guard !isBatchSyncing else { continue }

            DDLogInfo("\(batch.count) updates received from WpApiCache")

            #if DEBUG
            for hook in batch {
                DDLogDebug("  |- \(hook.action) to \(hook.table) at row \(hook.rowId)")
            }
            #endif

            let listInfo = collection.listInfo()

            DDLogInfo("List info: \(String(describing: listInfo))")

            do {
                let metadataItems = try await collection.loadItems()
                withAnimation {
                    if self.listInfo != listInfo {
                        self.listInfo = listInfo
                    }
                    updateItems(from: metadataItems)
                }
            } catch {
                DDLogError("Failed to get collection items: \(error)")
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
            DDLogError("Failed to refresh posts: \(error)")
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
            DDLogError("Failed to refresh all pages: \(error)")
            self.show(error: error)
        }
    }

    private var shouldDisplayHierarchy: Bool {
        isHierarchical && (filter.status == .publish || filter.status == .custom("any"))
    }

    private func updateItems(from metadataItems: [PostMetadataCollectionItem]) {
        let items = metadataItems.map { CustomPostCollectionItem(item: $0, blog: blog, filterStatus: filter.status) }

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

    private func show(error: Error) {
        // TODO: Ignore error https://github.com/Automattic/wordpress-rs/pull/1227
        self.error = error

        if !items.isEmpty {
            // Show an error notice, on top of the list content.
            Notice(error: error).post()
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
    let filterStatus: PostStatus?

    init(
        date: Date,
        title: String?,
        content: String?,
        authorName: String? = nil,
        status: PostStatus = .publish,
        sticky: Bool = false,
        featuredMedia: MediaId? = nil,
        filterStatus: PostStatus? = nil
    ) {
        self.date = date
        self.title = title
        self.content = content
        self.authorName = authorName
        self.status = status
        self.sticky = sticky
        self.featuredMedia = featuredMedia
        self.filterStatus = filterStatus
    }

    init(_ entity: AnyPostWithEditContext, blog: Blog, contentLimit: Int = 100, filterStatus: PostStatus? = nil) {
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
        self.filterStatus = filterStatus
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

        // Each tab filters by a specific status. Show a status badge when the
        // post's status doesn't match the tab's filter, since it would be redundant
        // otherwise. The "All" tab uses `.custom("any")` which never matches any
        // post status, so non-published posts always get a badge there.
        let showStatus = filterStatus == .custom("any") ? status != .publish : status != filterStatus
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

private enum Strings {
    static let sticky = NSLocalizedString(
        "customPostList.badge.sticky",
        value: "Sticky",
        comment: "Badge shown in the post list for sticky posts"
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

    init(item: PostMetadataCollectionItem, blog: Blog, filterStatus: PostStatus? = nil) {
        let id = item.id

        switch item.state {
        case .fresh(let entity):
            self = .ready(id: id, post: CustomPostCollectionDisplayPost(entity.data, blog: blog, filterStatus: filterStatus), fullPost: entity.data)

        case .stale(let entity):
            self = .stale(id: id, post: CustomPostCollectionDisplayPost(entity.data, blog: blog, filterStatus: filterStatus))

        case .fetchingWithData(let entity):
            self = .refreshing(id: id, post: CustomPostCollectionDisplayPost(entity.data, blog: blog, filterStatus: filterStatus))

        case .fetching:
            self = .fetching(id: id)

        case .missing:
            self = .missing(id: id)

        case .failed(let error):
            self = .error(id: id, message: error)

        case .failedWithData(let error, let entity):
            self = .errorWithData(id: id, message: error, post: CustomPostCollectionDisplayPost(entity.data, blog: blog, contentLimit: 50, filterStatus: filterStatus))
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
