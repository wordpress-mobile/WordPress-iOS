import Combine
import Foundation

/// One instance per filter tab, alive for the screen's lifetime, so switching
/// tabs never refetches or loses scroll content (the legacy screen's failure
/// mode). Pages accumulate in memory; there is no persistence by design.
@MainActor
final class CommentsListViewModel: ObservableObject {
    /// Where the tab stands with page one. Load-more state (`isLoadingMore`,
    /// `loadMoreFailed`) is an orthogonal axis and stays separate.
    enum FirstPageState: Equatable {
        /// Never appeared; no request made yet.
        case idle
        /// The initial page-one fetch is in flight. `items` is empty or a
        /// placeholder subset borrowed from the All tab meanwhile.
        case loading
        /// The initial fetch failed: full-screen error with retry.
        case failed
        /// Page one landed; `items` reflect the last fetch plus in-place
        /// event corrections.
        case loaded
        /// A change event couldn't be reconciled in place (see `apply(_:)`);
        /// page one is refetching behind the outdated rows.
        case reloading
        /// The rows are outdated and a page-one reload is pending: either
        /// just scheduled by `markStale`, or deferred to the next appearance
        /// after a reload attempt failed.
        case awaitingReload
    }

    let filter: CommentsListFilter

    @Published private(set) var items: [CommentListItem] = []
    @Published private(set) var state: FirstPageState = .idle
    @Published private(set) var isLoadingMore = false
    @Published private(set) var loadMoreFailed = false

    private let service: any CommentsServiceProtocol
    private let seedItems: (@MainActor () -> [CommentListItem])?
    private let onItemsAppended: (@MainActor ([CommentListItem]) -> Void)?
    private var nextPage: CommentsPageToken?
    /// The IDs of `items`, for O(1) membership checks.
    private var seenIDs: Set<Int64> = []
    private var eventSubscription: AnyCancellable?
    /// Number of `fetchPage` calls currently awaiting the service, so an
    /// invalidation only bumps `generation` when there is something to discard.
    private var inFlightFetchCount = 0
    /// Bumped whenever the list is reset to page one (first load or refresh).
    /// A `loadMore` started before a reset carries the old value and discards
    /// its result on completion, so a slow page fetched from an obsolete cursor
    /// can never append onto or overwrite the refreshed list.
    private var generation = 0

    /// Page one has landed at least once: `items` are real rows, if possibly
    /// outdated.
    var hasLoaded: Bool {
        switch state {
        case .loaded, .reloading, .awaitingReload: true
        case .idle, .loading, .failed: false
        }
    }

    var canLoadMore: Bool {
        hasLoaded && nextPage != nil && !isLoadingMore && !loadMoreFailed
    }

    var showsEmptyState: Bool {
        hasLoaded && items.isEmpty
    }

    init(
        filter: CommentsListFilter,
        service: any CommentsServiceProtocol,
        seedItems: (@MainActor () -> [CommentListItem])? = nil,
        onItemsAppended: (@MainActor ([CommentListItem]) -> Void)? = nil,
        changeEvents: AnyPublisher<CommentChangeEvent, Never>? = nil
    ) {
        self.filter = filter
        self.service = service
        self.seedItems = seedItems
        self.onItemsAppended = onItemsAppended
        eventSubscription = changeEvents?.sink { [weak self] in self?.apply($0) }
    }

    func onAppear() async {
        switch state {
        case .loading, .loaded, .reloading:
            return
        case .awaitingReload:
            // A stale reload keeps its real (if outdated) rows; seeding only
            // applies to the very first load.
            await loadFirstPage(as: .reloading)
        case .idle, .failed:
            if let seeded = seedItems?(), !seeded.isEmpty {
                items = seeded
                seenIDs = Set(seeded.map(\.id))
            }
            await loadFirstPage(as: .loading)
        }
    }

    /// Retries a stale reload that failed while the tab was off screen. A no-op
    /// in every other state, so it never starts a first load.
    func reloadIfStale() async {
        guard state == .awaitingReload else { return }
        await onAppear()
    }

    /// Applies a moderation change event, keeping this tab's items consistent
    /// without a full refetch where possible.
    func apply(_ event: CommentChangeEvent) {
        switch event {
        case .statusChanged(let id, let to):
            if filter.matches(to) {
                if seenIDs.contains(id), let index = items.firstIndex(where: { $0.id == id }) {
                    // Correct the row in place, then invalidate in-flight
                    // fetches: an older page-one fetch (initial or stale reload)
                    // captured before this correction would otherwise pass its
                    // generation guard and overwrite the corrected status.
                    items[index].status = to
                    invalidateInFlightFetches()
                } else if hasLoaded {
                    // The comment now belongs here but a paged list cannot know
                    // the correct insert position; refetch on next appearance.
                    // markStale also invalidates any in-flight fetch.
                    markStale()
                } else {
                    // Belongs but absent while an initial (seeded) page-one load
                    // is still in flight: invalidate it so it re-converges to a
                    // complete post-mutation page that includes this comment,
                    // rather than accepting a pre-mutation page that omits it.
                    invalidateInFlightFetches()
                }
            } else {
                removeItem(id: id)
            }
        case .deleted(let id):
            removeItem(id: id)
        }
    }

    private func removeItem(id: Int64) {
        if seenIDs.remove(id) != nil {
            items.removeAll { $0.id == id }
        }
        // Invalidate even when the row was absent: a page still in flight
        // captured the pre-removal generation and could still deliver the
        // comment (as a fresh id) after it was removed elsewhere.
        invalidateInFlightFetches()
    }

    /// Marks the tab stale and reloads page one right away, so a visible tab
    /// doesn't wait for a tab switch. Callers guard `hasLoaded`. A reload
    /// already in flight keeps its state: its fetch is invalidated below and
    /// refetches itself, and `onAppear` ignores the extra kick.
    private func markStale() {
        if state == .loaded {
            state = .awaitingReload
        }
        invalidateInFlightFetches()
        Task { await onAppear() }
    }

    /// Bumps `generation` so any list fetch already in flight (which captured
    /// the earlier value) discards its result on completion. A no-op when no
    /// fetch is in flight: there is nothing to discard.
    private func invalidateInFlightFetches() {
        if inFlightFetchCount > 0 {
            generation &+= 1
        }
    }

    /// The result of a paged fetch that has already waited for in-flight
    /// moderation to settle.
    private enum FetchOutcome {
        /// A moderation event bumped `generation` while the fetch was in flight,
        /// so the returned page predates it and must not be treated as
        /// authoritative.
        case invalidated
        case loaded(CommentsPage)
        case failed
    }

    /// Fetches a page and reports whether a moderation event invalidated it
    /// mid-flight. The generation guard catches an event that lands (post-
    /// success, so describing committed server state) while the request is in
    /// flight and would otherwise overwrite an in-place correction or restore a
    /// removed row; the caller decides whether to retry until convergence (page
    /// one) or drop the page (pagination/refresh).
    ///
    /// It's possible that a page requested before a mutation commits is applied
    /// before that mutation's success event lands, so it briefly shows the
    /// pre-action state; the success event then corrects membership in place. We
    /// consider that an edge case and accept the risk.
    private func fetchPage(nextPage token: CommentsPageToken?) async -> FetchOutcome {
        let requestGeneration = generation
        inFlightFetchCount += 1
        defer { inFlightFetchCount -= 1 }
        do {
            let page = try await service.listComments(filter: filter, nextPage: token)
            guard requestGeneration == generation else { return .invalidated }
            return .loaded(page)
        } catch {
            guard requestGeneration == generation else { return .invalidated }
            return .failed
        }
    }

    func retryFirstPage() async {
        guard state == .failed else { return }
        await loadFirstPage(as: .loading)
    }

    func loadMore() async {
        guard canLoadMore, let token = nextPage else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        switch await fetchPage(nextPage: token) {
        case .invalidated:
            // Fetched from an obsolete cursor or predating a moderation; drop it.
            break
        case .loaded(let page):
            append(page: page)
        case .failed:
            loadMoreFailed = true
        }
    }

    func retryLoadMore() async {
        loadMoreFailed = false
        await loadMore()
    }

    func refresh() async {
        // On invalidation or error, keep the current content: the in-place
        // `apply` already reflects moderation, and the user can pull again.
        guard case .loaded(let page) = await fetchPage(nextPage: nil) else { return }
        replace(with: page)
        // A fresh full page is authoritative, so a tab awaiting a stale reload
        // is no longer stale. A page-one loop still in flight settles its own
        // state once its (now invalidated) fetch reconverges.
        switch state {
        case .loading, .reloading:
            break
        case .idle, .failed, .loaded, .awaitingReload:
            state = .loaded
        }
    }

    /// Runs the page-one fetch loop from `loadingState` (`.loading` for the
    /// initial load, `.reloading` for a stale reload) and settles into the
    /// matching terminal state.
    private func loadFirstPage(as loadingState: FirstPageState) async {
        state = loadingState
        // Loop so a request invalidated mid-flight always converges: a
        // stale-triggered onAppear can't reschedule while this is running (the
        // re-entry guard), so a discard-and-return would strand the tab stale
        // until a lifecycle event. With no further events the next fetch
        // matches and completes, so this can't spin.
        while true {
            switch await fetchPage(nextPage: nil) {
            case .invalidated:
                continue
            case .loaded(let page):
                replace(with: page)
                state = .loaded
                return
            case .failed:
                if loadingState == .loading {
                    // Initial (or seeded) load failure: full-screen error + retry.
                    state = .failed
                } else {
                    // A stale reload fails silently: keep the outdated rows and
                    // try again on the next appearance.
                    state = .awaitingReload
                }
                return
            }
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
