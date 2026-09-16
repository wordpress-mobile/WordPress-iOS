import Combine
import Foundation

/// Results for the submitted query, alive for the screen's lifetime and reset
/// when search is dismissed. Unlike the list tabs, moderation never refetches:
/// events correct loaded rows in place and are replayed onto later pages.
@MainActor
final class CommentsSearchViewModel: ObservableObject {
    /// Where the results stand with page one. Load-more state is an
    /// orthogonal axis and stays separate.
    enum State: Equatable {
        /// Nothing submitted yet.
        case prompt
        /// The first page for a new query is in flight; `items` is empty.
        case loading
        /// The first page failed: full-screen error with retry.
        case failed
        /// Page one landed; `items` reflect the last fetch plus event corrections.
        case loaded
        /// Pull-to-refresh is refetching page one behind the current rows.
        case refreshing
        /// The refresh failed; the rows are kept with a retry footer.
        case refreshFailed
    }

    @Published private(set) var items: [CommentListItem] = []
    @Published private(set) var state: State = .prompt
    @Published private(set) var isLoadingMore = false
    @Published private(set) var loadMoreFailed = false
    @Published private(set) var nextPage: CommentsPageToken?
    private(set) var submittedQuery: String?

    private let service: any CommentsServiceProtocol
    private let onItemsAppended: @MainActor ([CommentListItem]) -> Void
    private var eventSubscription: AnyCancellable?
    /// Bumped whenever the results are reset (submit, refresh, cancel). A fetch
    /// started before carries the old value and discards its result.
    private var generation = 0
    /// Events since the current baseline, replayed onto pages fetched later so
    /// a page captured before a moderation can't resurrect the old row.
    private var excludedIDs: Set<Int64> = []
    private var statuses: [Int64: CommentListItem.Status] = [:]
    private var snippets: [Int64: String] = [:]

    var canLoadMore: Bool {
        state == .loaded && nextPage != nil && !isLoadingMore && !loadMoreFailed
    }

    init(
        service: any CommentsServiceProtocol,
        onItemsAppended: @escaping @MainActor ([CommentListItem]) -> Void = { _ in },
        changeEvents: AnyPublisher<CommentChangeEvent, Never>? = nil
    ) {
        self.service = service
        self.onItemsAppended = onItemsAppended
        eventSubscription = changeEvents?.sink { [weak self] in self?.apply($0) }
    }

    /// Searches for the trimmed `text`. Resubmitting the in-flight query is a
    /// no-op; resubmitting a settled one reloads.
    func submit(_ text: String) async {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        guard query != submittedQuery || (state != .loading && state != .refreshing) else { return }
        submittedQuery = query
        await loadFirstPage(keepingItems: false)
    }

    func refresh() async {
        guard submittedQuery != nil else { return }
        await loadFirstPage(keepingItems: true)
    }

    func retry() async {
        switch state {
        case .refreshFailed:
            await refresh()
        case .failed:
            await loadFirstPage(keepingItems: false)
        case .loaded:
            guard loadMoreFailed else { return }
            loadMoreFailed = false
            await loadMore()
        case .prompt, .loading, .refreshing:
            return
        }
    }

    func cancel() {
        generation &+= 1
        submittedQuery = nil
        items = []
        nextPage = nil
        state = .prompt
        isLoadingMore = false
        loadMoreFailed = false
        resetEvents()
    }

    func loadMore() async {
        guard canLoadMore, let query = submittedQuery, let nextPage else { return }
        isLoadingMore = true
        switch await fetchPage(query: query, nextPage: nextPage) {
        case .invalidated:
            // The reset that invalidated this fetch already cleared the flag.
            return
        case .loaded(let page):
            let appended = reconciled(page.items, excluding: Set(items.map(\.id)))
            items.append(contentsOf: appended)
            self.nextPage = page.nextPage
            onItemsAppended(appended)
        case .failed:
            // Scrolling the footer away cancels its task; allow it to load again.
            loadMoreFailed = !Task.isCancelled
        }
        isLoadingMore = false
    }

    private func loadFirstPage(keepingItems: Bool) async {
        guard let query = submittedQuery else { return }
        generation &+= 1
        resetEvents()
        nextPage = nil
        isLoadingMore = false
        loadMoreFailed = false
        state = keepingItems ? .refreshing : .loading
        if !keepingItems {
            items = []
        }
        switch await fetchPage(query: query, nextPage: nil) {
        case .invalidated:
            return
        case .loaded(let page):
            items = reconciled(page.items, excluding: [])
            nextPage = page.nextPage
            state = .loaded
            onItemsAppended(items)
        case .failed:
            state = keepingItems ? .refreshFailed : .failed
        }
    }

    private enum FetchOutcome {
        /// A reset bumped `generation` while the fetch was in flight.
        case invalidated
        case loaded(CommentsPage)
        case failed
    }

    private func fetchPage(query: String, nextPage: CommentsPageToken?) async -> FetchOutcome {
        let requestGeneration = generation
        do {
            let page = try await service.searchComments(query: query, nextPage: nextPage)
            guard requestGeneration == generation else { return .invalidated }
            return .loaded(page)
        } catch {
            guard requestGeneration == generation else { return .invalidated }
            return .failed
        }
    }

    private func resetEvents() {
        excludedIDs = []
        statuses = [:]
        snippets = [:]
    }

    /// Replays recorded events onto a fetched page and drops rows already in
    /// `excluding` or repeated within the page (offset paging can re-serve rows).
    private func reconciled(_ rows: [CommentListItem], excluding: Set<Int64>) -> [CommentListItem] {
        var seen = excluding
        return rows.compactMap { row in
            guard !excludedIDs.contains(row.id), seen.insert(row.id).inserted else { return nil }
            var row = row
            if let status = statuses[row.id] { row.status = status }
            if let snippet = snippets[row.id] { row.snippet = snippet }
            return row
        }
    }

    private func apply(_ event: CommentChangeEvent) {
        guard submittedQuery != nil else { return }
        switch event {
        case .statusChanged(let id, let status):
            if CommentsListFilter.all.matches(status) {
                statuses[id] = status
                if let index = items.firstIndex(where: { $0.id == id }) {
                    items[index].status = status
                }
            } else {
                // Kept until a new server baseline, even after restoration.
                exclude(id)
            }
        case .deleted(let id):
            exclude(id)
        case .contentChanged(let id, let html, _):
            let snippet = CommentListItem.snippet(fromHTML: html)
            snippets[id] = snippet
            if let index = items.firstIndex(where: { $0.id == id }) {
                items[index].snippet = snippet
            }
        case .replyCreated:
            return
        }
    }

    private func exclude(_ id: Int64) {
        excludedIDs.insert(id)
        if let index = items.firstIndex(where: { $0.id == id }) {
            items.remove(at: index)
        }
    }
}
