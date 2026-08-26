import Foundation

/// One instance per filter tab, alive for the screen's lifetime, so switching
/// tabs never refetches or loses scroll content (the legacy screen's failure
/// mode). Pages accumulate in memory; there is no persistence by design.
@MainActor
final class CommentsListViewModel: ObservableObject {
    let filter: CommentsListFilter

    @Published private(set) var items: [CommentListItem] = []
    // TODO: Consider folding the first-page state (isShowingSeededPlaceholder,
    // isLoadingFirstPage, firstPageFailed, hasLoaded, showsEmptyState) into a
    // single ScreenState enum so illegal combinations become unrepresentable.
    // The load-more state (isLoadingMore, loadMoreFailed) is an orthogonal axis
    // and would stay separate. Deferred as a non-behavioral cleanup.
    @Published private(set) var isShowingSeededPlaceholder = false
    @Published private(set) var isLoadingFirstPage = false
    @Published private(set) var firstPageFailed = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var loadMoreFailed = false

    private(set) var hasLoaded = false

    private let service: any CommentsServiceProtocol
    private let seedItems: (@MainActor () -> [CommentListItem])?
    private let onItemsAppended: (@MainActor ([CommentListItem]) -> Void)?
    private var nextPage: CommentsPageToken?
    private var seenIDs: Set<Int64> = []
    /// Bumped whenever the list is reset to page one (first load or refresh).
    /// A `loadMore` started before a reset carries the old value and discards
    /// its result on completion, so a slow page fetched from an obsolete cursor
    /// can never append onto or overwrite the refreshed list.
    private var generation = 0

    var canLoadMore: Bool {
        hasLoaded && nextPage != nil && !isShowingSeededPlaceholder && !isLoadingMore && !loadMoreFailed
    }

    var showsEmptyState: Bool {
        hasLoaded && items.isEmpty && !firstPageFailed
    }

    init(
        filter: CommentsListFilter,
        service: any CommentsServiceProtocol,
        seedItems: (@MainActor () -> [CommentListItem])? = nil,
        onItemsAppended: (@MainActor ([CommentListItem]) -> Void)? = nil
    ) {
        self.filter = filter
        self.service = service
        self.seedItems = seedItems
        self.onItemsAppended = onItemsAppended
    }

    func onAppear() async {
        guard !hasLoaded, !isLoadingFirstPage else { return }
        if let seeded = seedItems?(), !seeded.isEmpty {
            items = seeded
            isShowingSeededPlaceholder = true
        }
        await loadFirstPage()
    }

    func retryFirstPage() async {
        guard !isLoadingFirstPage else { return }
        await loadFirstPage()
    }

    func loadMore() async {
        guard canLoadMore, let token = nextPage else { return }
        let requestGeneration = generation
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let page = try await service.listComments(filter: filter, nextPage: token)
            // A refresh or first-load reset that landed while this page was in
            // flight makes it stale; dropping it avoids appending items fetched
            // from an obsolete cursor onto the refreshed list.
            guard requestGeneration == generation else { return }
            append(page: page)
        } catch {
            guard requestGeneration == generation else { return }
            loadMoreFailed = true
        }
    }

    func retryLoadMore() async {
        loadMoreFailed = false
        await loadMore()
    }

    func refresh() async {
        do {
            let page = try await service.listComments(filter: filter, nextPage: nil)
            replace(with: page)
        } catch {
            // Keep stale content on refresh failure; the design surfaces no
            // blocking error here.
        }
    }

    private func loadFirstPage() async {
        isLoadingFirstPage = true
        firstPageFailed = false
        defer { isLoadingFirstPage = false }
        do {
            let page = try await service.listComments(filter: filter, nextPage: nil)
            replace(with: page)
            hasLoaded = true
            isShowingSeededPlaceholder = false
        } catch {
            firstPageFailed = items.isEmpty || isShowingSeededPlaceholder
        }
    }

    private func replace(with page: CommentsPage) {
        generation &+= 1
        seenIDs = Set(page.items.map(\.id))
        items = page.items
        nextPage = page.nextPage
        loadMoreFailed = false
        onItemsAppended?(page.items)
    }

    private func append(page: CommentsPage) {
        // Offset paging can re-serve rows when the result set shifts between
        // requests; duplicate IDs would also break SwiftUI's ForEach diffing.
        let fresh = page.items.filter { !seenIDs.contains($0.id) }
        seenIDs.formUnion(fresh.map(\.id))
        items.append(contentsOf: fresh)
        nextPage = page.nextPage
        onItemsAppended?(fresh)
    }
}
