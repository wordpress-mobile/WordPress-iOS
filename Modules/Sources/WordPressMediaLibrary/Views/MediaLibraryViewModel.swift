import Foundation
import SwiftUI
import WordPressAPI
import WordPressAPIInternal
import WordPressCore

@MainActor
final class MediaLibraryViewModel: ObservableObject {
    private let client: WordPressClient
    private let tracker: any MediaTracker

    /// Cached lazy resolution of `WpService` + a
    /// `MediaMetadataCollectionWithEditContext` for the current `filter`.
    /// Replaced on every `setFilter(_:)`; evicted on non-cancellation
    /// throws in `resolveCollection`.
    private var collectionTask: Task<MediaMetadataCollectionWithEditContext, Error>?

    /// Monotonically increments on every `setFilter(_:)`. Methods that
    /// publish into `items` / `listInfo` / `error` from an `await` snapshot
    /// this at entry and guard every state write on
    /// `self.generation == snapshot && !Task.isCancelled`. Both conditions
    /// are load-bearing: the generation check rejects writes from an older
    /// filter whose body is still finishing its `await` chain, and the
    /// cancellation check rejects writes after view dismantle. Swift task
    /// cancellation is cooperative — an FFI await may resume normally
    /// without throwing `CancellationError`, so the cancellation flag has
    /// to be consulted explicitly at every write site.
    private var generation: UInt64 = 0

    @Published private(set) var filter: MediaGridFilter = .initial
    @Published private(set) var items: [MediaGridItem] = []
    @Published private(set) var listInfo: ListInfo?
    @Published private(set) var error: Error?
    @Published private(set) var isRefreshing = false

    @Published var isAspectRatioModeEnabled: Bool {
        didSet {
            AspectRatioPreference.save(isAspectRatioModeEnabled)
            tracker.track(.mediaLibraryGridModeToggled(isAspectRatio: isAspectRatioModeEnabled))
        }
    }

    private var isLoadingNextPage = false

    var shouldDisplayInitialLoading: Bool { items.isEmpty && isRefreshing }
    var shouldDisplayEmpty: Bool {
        items.isEmpty && !isRefreshing && error == nil
            && filter.search.isEmpty && filter.kind == nil
    }
    var shouldDisplayFilterEmpty: Bool {
        items.isEmpty && !isRefreshing && error == nil
            && filter.search.isEmpty && filter.kind != nil
    }
    var shouldDisplaySearchEmpty: Bool {
        items.isEmpty && !isRefreshing && error == nil && !filter.search.isEmpty
    }
    func errorToDisplay() -> Error? { items.isEmpty ? error : nil }

    init(client: WordPressClient, tracker: any MediaTracker) {
        self.client = client
        self.tracker = tracker
        self.isAspectRatioModeEnabled = AspectRatioPreference.load()
        // Eagerly schedule the first collection task so `.task(id: filter)`
        // can await it on first appearance without re-creation.
        self.collectionTask = makeCollectionTask(for: .initial)
    }

    /// Builds a Task that awaits `client.service` (actor-isolated) and
    /// constructs a `MediaMetadataCollectionWithEditContext` for the given
    /// filter. The Task does not capture `self`; it captures only `client`.
    private func makeCollectionTask(
        for filter: MediaGridFilter
    ) -> Task<MediaMetadataCollectionWithEditContext, Error> {
        Task { [client] in
            let service = try await client.service
            return service.media()
                .createMediaMetadataCollectionWithEditContext(
                    filter: filter.asMediaListFilter(),
                    perPage: 100
                )
        }
    }

    /// Awaits the cached collection task. On a non-cancellation throw,
    /// evicts the cached task IF the generation hasn't advanced — so the
    /// next call (e.g. Retry) builds a fresh task. Cancellation throws
    /// don't evict because they're expected during filter change and
    /// `setFilter` already installed the replacement.
    private func resolveCollection() async throws -> MediaMetadataCollectionWithEditContext {
        if collectionTask == nil {
            collectionTask = makeCollectionTask(for: filter)
        }
        let task = collectionTask!
        let snapshot = generation
        do {
            return try await task.value
        } catch {
            if !(error is CancellationError), generation == snapshot {
                collectionTask = nil
            }
            throw error
        }
    }

    func setFilter(_ newFilter: MediaGridFilter) {
        guard filter != newFilter else { return }
        let oldFilter = filter
        collectionTask?.cancel()
        generation &+= 1
        withAnimation {
            filter = newFilter
            items = []
            listInfo = nil
            error = nil
            // Flip the loading overlay on in the SAME render tick that
            // clears `items` so the between-task render gap doesn't paint
            // the empty / filter-empty / search-empty state for one frame
            // before refresh() runs on the next MainActor turn.
            isRefreshing = true
        }
        collectionTask = makeCollectionTask(for: newFilter)
        if newFilter.kind != oldFilter.kind {
            tracker.track(.mediaLibraryFilterChanged(kind: newFilter.kind))
        }
        if newFilter.search != oldFilter.search, !newFilter.search.isEmpty {
            tracker.track(.mediaLibrarySearched(queryLength: newFilter.search.count))
        }
    }

    func refresh(pullToRefresh: Bool = false) async {
        let snapshot = generation
        // Idempotent — already true after setFilter; covers first .task
        // invocation on view appearance (where setFilter never ran).
        isRefreshing = true
        // Clear stale error so a successful retry that returns zero items
        // shows the empty state rather than the previous failure. setFilter
        // also clears errors, but Retry and pull-to-refresh come through
        // here without changing the filter.
        error = nil
        defer {
            if generation == snapshot, !Task.isCancelled {
                isRefreshing = false
            }
        }
        if !pullToRefresh {
            await loadCachedItems(snapshot: snapshot)
        }
        await fetchPageOne(snapshot: snapshot)
    }

    private func loadCachedItems(snapshot: UInt64) async {
        do {
            let collection = try await resolveCollection()
            await loadItems(from: collection, snapshot: snapshot)
        } catch {
            if !(error is CancellationError) {
                Loggers.mediaLibrary.error("Failed to load cached items: \(error)")
            }
        }
    }

    private func fetchPageOne(snapshot: UInt64) async {
        do {
            let collection = try await resolveCollection()
            guard generation == snapshot, !Task.isCancelled else { return }
            _ = try await collection.refresh()
            await loadItems(from: collection, snapshot: snapshot)
        } catch {
            if !(error is CancellationError) {
                Loggers.mediaLibrary.error("Media library refresh failed: \(error)")
                show(error: error, snapshot: snapshot)
            }
        }
    }

    /// Long-running cache observer. Restarted by `.task(id: viewModel.filter)`
    /// on every filter change, so the snapshot captured here stays tied to
    /// the active-at-start generation.
    func handleDataChanges() async {
        let snapshot = generation
        let collection: MediaMetadataCollectionWithEditContext
        do {
            collection = try await resolveCollection()
        } catch {
            return
        }

        let batches = await client.cache.databaseUpdatesPublisher()
            .filter { @Sendable [weak collection] in
                collection?.isRelevantUpdate(hook: $0) == true
            }
            .collect(.byTime(DispatchQueue.main, .milliseconds(50)))
            .values

        for await _ in batches {
            await loadItems(from: collection, snapshot: snapshot)
        }
    }

    func loadNextPage() async throws {
        guard !isRefreshing, !isLoadingNextPage else { return }
        isLoadingNextPage = true
        defer { isLoadingNextPage = false }

        let snapshot = generation
        let collection = try await resolveCollection()
        guard !collection.isSyncing,
            collection.hasMorePages() ?? true,
            generation == snapshot,
            !Task.isCancelled
        else { return }

        if collection.listInfo()?.currentPage == nil {
            _ = try await collection.refresh()
        } else {
            _ = try await collection.loadNextPage()
        }
        await loadItems(from: collection, snapshot: snapshot)
    }

    func loadNextPageIfNeeded(after item: MediaGridItem) async {
        let trailingThreshold = 10
        guard items.suffix(trailingThreshold).contains(where: { $0.id == item.id }) else {
            return
        }
        // Capture the snapshot BEFORE the await so a filter change during
        // pagination can't route the error into the new generation's state.
        let snapshot = generation
        do {
            try await loadNextPage()
        } catch {
            if !(error is CancellationError) {
                Loggers.mediaLibrary.error("Media library loadNextPage failed: \(error)")
                show(error: error, snapshot: snapshot)
            }
        }
    }

    private func loadItems(
        from collection: MediaMetadataCollectionWithEditContext,
        snapshot: UInt64
    ) async {
        do {
            let listInfo = collection.listInfo()
            let metadataItems = try await collection.loadItems()
            guard generation == snapshot, !Task.isCancelled else { return }
            self.listInfo = listInfo
            withAnimation {
                self.items = metadataItems.map(MediaGridItem.init(item:))
            }
        } catch {
            if !(error is CancellationError) {
                Loggers.mediaLibrary.error("Failed to load items: \(error)")
            }
        }
    }

    private func show(error: Error, snapshot: UInt64) {
        if case FetchError.StaleLoadMore = error { return }
        guard generation == snapshot, !Task.isCancelled else { return }
        self.error = error
    }
}

// Mirrors the private extension in `CustomPostListViewModel.swift`.
private extension ListInfo {
    var isSyncing: Bool {
        state == .fetchingFirstPage || state == .fetchingNextPage
    }
}

private extension MediaMetadataCollectionWithEditContext {
    var isSyncing: Bool { listInfo()?.isSyncing == true }
}
