import Foundation
import SwiftUI
import WordPressAPI
import WordPressAPIInternal
import WordPressCore

@MainActor
final class MediaLibraryViewModel: ObservableObject {
    private let client: WordPressClient
    private let tracker: any MediaTracker
    private var collectionTask: Task<MediaMetadataCollectionWithEditContext, Error>?
    private var isLoadingNextPage = false

    @Published private(set) var items: [MediaListItem] = []
    @Published private(set) var listInfo: ListInfo?
    @Published private(set) var error: Error?
    /// Set to true while `refresh()` is in flight. Drives the cold-cache
    /// initial-loading spinner explicitly, instead of inferring from the
    /// wp-rs collection's `listInfo.isSyncing` (which only updates after
    /// the cache observer wakes — racy).
    @Published private(set) var isRefreshing = false

    var shouldDisplayInitialLoading: Bool { items.isEmpty && isRefreshing }
    var shouldDisplayEmptyView: Bool { items.isEmpty && !isRefreshing && error == nil }
    func errorToDisplay() -> Error? { items.isEmpty ? error : nil }

    init(client: WordPressClient, tracker: any MediaTracker) {
        self.client = client
        self.tracker = tracker
    }

    /// Resolves WpService and constructs the collection, exactly once.
    /// Cached as a Task so concurrent callers (the cache observer task and
    /// the refresh task both wake at view appearance) await the same
    /// construction. Same pattern WordPressClient itself uses for site
    /// info / current user.
    private func resolveCollection() async throws -> MediaMetadataCollectionWithEditContext {
        if let collectionTask {
            return try await collectionTask.value
        }
        let task = Task<MediaMetadataCollectionWithEditContext, Error> { [client] in
            let service = try await client.service
            return service.media()
                .createMediaMetadataCollectionWithEditContext(
                    filter: MediaListFilter(),
                    perPage: 100
                )
        }
        self.collectionTask = task
        return try await task.value
    }

    /// Loads cached items into `items` immediately so the first paint isn't
    /// blocked on the network round-trip.
    func loadCachedItems() async {
        do {
            let collection = try await resolveCollection()
            await loadItems(from: collection)
        } catch {
            Loggers.mediaLibrary.error("Failed to load cached items: \(error)")
        }
    }

    /// Single entry point for the SwiftUI .task block. Owns isRefreshing
    /// across BOTH loadCachedItems() and refresh() so the empty state can't
    /// flash in the microsecond window between them on cold-cache first
    /// open. SwiftUI re-evaluates body on every @Published change, so even
    /// a single MainActor scheduling hop where (items.isEmpty &&
    /// !isRefreshing && error == nil) holds will paint the empty view.
    func performInitialLoad() async {
        isRefreshing = true
        defer { isRefreshing = false }
        await loadCachedItems()
        await refresh()
    }

    func refresh() async {
        // isRefreshing drives the cold-cache initial-loading UI deterministically,
        // independent of the wp-rs cache observer's wake timing.
        isRefreshing = true
        defer { isRefreshing = false }

        // Clear stale error from any previous failed attempt so a successful
        // retry unblocks the empty/list UI even when the new fetch returns
        // zero items. Without this, errorToDisplay() would keep showing the
        // old error because items.isEmpty stays true.
        self.error = nil

        do {
            let collection = try await resolveCollection()
            _ = try await collection.refresh()
            // Reload items directly after refresh succeeds, instead of
            // relying on the cache observer to wake up. SwiftUI doesn't
            // order sibling .task modifiers, so handleDataChanges() may not
            // have subscribed before refresh wrote to the cache. This makes
            // the cold-cache first load deterministic; handleDataChanges()
            // handles subsequent updates only.
            await loadItems(from: collection)
        } catch {
            Loggers.mediaLibrary.error("Media library refresh failed: \(error)")
            show(error: error)
        }
    }

    func pullToRefresh() async { await refresh() }

    /// Long-running cache observer for SUBSEQUENT updates only — the initial
    /// load is handled deterministically by `refresh()` calling
    /// `loadItems(from:)` directly.
    func handleDataChanges() async {
        let collection: MediaMetadataCollectionWithEditContext
        do {
            collection = try await resolveCollection()
        } catch {
            // Collection couldn't be constructed; nothing to observe.
            return
        }

        // The filter closure runs synchronously on whichever thread the
        // upstream publisher emits on — for wp-rs's `databaseUpdatesPublisher()`
        // that's the SQLite worker thread (NotificationCenter post from the
        // rusqlite update hook). Marking it `@Sendable` opts out of the
        // implicit `@MainActor` isolation that Swift 6 would otherwise
        // inherit from the enclosing class, so the cheap `isRelevantUpdate`
        // check stays on the background thread without tripping the runtime
        // MainActor assertion. The downstream `.collect(.byTime(DispatchQueue.main, …))`
        // hops to main before delivering batches, so the `for await` body
        // runs on main where it mutates `@Published` state.
        let batches = await client.cache.databaseUpdatesPublisher()
            .filter { @Sendable [weak collection] in collection?.isRelevantUpdate(hook: $0) == true }
            .collect(.byTime(DispatchQueue.main, .milliseconds(50)))
            .values

        for await _ in batches {
            await loadItems(from: collection)
        }
    }

    // TODO: Pagination is temporary. A future change will switch the Media
    // Library to a full-library sync model rather than per-page fetches.
    func loadNextPage() async throws {
        // Two guards:
        //   1. !isRefreshing — warm-cache first open paints cached rows
        //      while the initial refresh is still in flight; trailing-row
        //      .onAppear can fire loadNextPage concurrently with that
        //      refresh. Defer pagination until the initial load completes.
        //   2. !isLoadingNextPage — trailing-N rows can each fire .onAppear
        //      in quick succession before the collection's listInfo
        //      reflects the sync, producing duplicate fetches and noisy
        //      StaleLoadMore errors. Mirrors the isLoadingMore guard in
        //      CustomPostListView.
        guard !isRefreshing, !isLoadingNextPage else { return }
        isLoadingNextPage = true
        defer { isLoadingNextPage = false }

        let collection = try await resolveCollection()
        guard !collection.isSyncing,
            collection.hasMorePages() ?? true
        else { return }
        if collection.listInfo()?.currentPage == nil {
            _ = try await collection.refresh()
        } else {
            _ = try await collection.loadNextPage()
        }
        await loadItems(from: collection)
    }

    // TODO: Pagination is temporary, see loadNextPage().
    func loadNextPageIfNeeded(after item: MediaListItem) async {
        // Trigger a fetch only when the row that just appeared is one of the
        // last few rows we have loaded — protects against firing for every
        // single .onAppear above the fold.
        let trailingThreshold = 10
        guard items.suffix(trailingThreshold).contains(where: { $0.id == item.id }) else {
            return
        }
        do {
            try await loadNextPage()
        } catch {
            Loggers.mediaLibrary.error("Media library loadNextPage failed: \(error)")
            show(error: error)
        }
    }

    /// Reads the current snapshot from the collection and updates @Published
    /// state. Shared by `loadCachedItems()`, `refresh()`, `loadNextPage()`,
    /// and `handleDataChanges()` so all reload paths funnel through the
    /// same code.
    private func loadItems(from collection: MediaMetadataCollectionWithEditContext) async {
        do {
            self.listInfo = collection.listInfo()
            let metadataItems = try await collection.loadItems()
            withAnimation {
                self.items = metadataItems.map(MediaListItem.init(item:))
            }
        } catch {
            Loggers.mediaLibrary.error("Failed to load items: \(error)")
        }
    }

    private func show(error: Error) {
        if case FetchError.StaleLoadMore = error { return }
        self.error = error
    }
}

// Mirrors the private extension in CustomPostListViewModel.
// `isSyncing` is NOT part of the wordpress-rs ListInfo surface (which
// exposes only state, currentPage, totalPages, totalItems, and perPage);
// this extension fills the gap.
private extension ListInfo {
    var isSyncing: Bool {
        state == .fetchingFirstPage || state == .fetchingNextPage
    }
}

private extension MediaMetadataCollectionWithEditContext {
    var isSyncing: Bool { listInfo()?.isSyncing == true }
}
