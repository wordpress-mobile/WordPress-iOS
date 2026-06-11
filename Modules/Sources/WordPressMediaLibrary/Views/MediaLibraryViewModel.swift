import Combine
import Foundation
import SwiftUI
import WordPressAPI
import WordPressAPIInternal
import WordPressCore

/// Backs a single media grid: the library (no query) or one search query.
/// Owns exactly one collection. The library instance also drives the
/// client-side `kind` filter; the search instance leaves `kind` nil, so its
/// `displayItems` equals `items`.
@MainActor
final class MediaLibraryViewModel: ObservableObject {
    typealias Collection = any MediaMetadataCollectionWithEditContextProtocol

    private let tracker: any MediaTracker
    private let client: WordPressClient
    private let collection: Collection

    @Published private(set) var items: [MediaGridItem] = []
    /// Stored, derived from `items` + `kind`. Recomputed only in `reload()` and
    /// `setKind(_:)` so the grid never re-filters during `body` evaluation.
    @Published private(set) var displayItems: [MediaGridItem] = []
    @Published private(set) var kind: MediaKind?
    @Published private(set) var error: Error?
    @Published private(set) var isLoadComplete = false

    /// Guards re-entrant loads. Safe because each instance owns one collection,
    /// so a skipped re-entrant call never loses a distinct load.
    private var isLoading = false

    /// Pure type-filter, extracted so it can be unit-tested directly with
    /// fixture items (a real collection can't yield known-kind items in tests).
    /// Unknown-kind items (`kind == nil`) match no specific type, so they
    /// appear only under "All".
    static func applyingKindFilter(_ items: [MediaGridItem], kind: MediaKind?) -> [MediaGridItem] {
        guard let kind else { return items }
        return items.filter { $0.kind == kind }
    }

    // MARK: Empty-state / overlay signals

    var shouldDisplayInitialLoading: Bool {
        items.isEmpty && !isLoadComplete && error == nil
    }
    var shouldDisplayEmpty: Bool {
        kind == nil && isLoadComplete && items.isEmpty && error == nil
    }
    var shouldDisplayFilterEmpty: Bool {
        kind != nil && isLoadComplete && displayItems.isEmpty && error == nil
    }
    func errorToDisplay() -> Error? {
        items.isEmpty ? error : nil
    }

    // MARK: Init

    /// Builds the collection from the wordpress-rs service: the library when
    /// `search` is nil, a search collection otherwise. `client` is retained so
    /// `observe()` can subscribe to the local cache's update stream.
    init(
        service: WpService,
        client: WordPressClient,
        tracker: any MediaTracker,
        search: String? = nil
    ) {
        self.tracker = tracker
        self.client = client
        self.collection = service.media()
            .createMediaMetadataCollectionWithEditContext(
                filter: MediaListFilter(search: search, mediaType: nil),
                perPage: 100
            )
    }

    // MARK: Filter mutator

    func setKind(_ newKind: MediaKind?) {
        guard kind != newKind else { return }
        withAnimation {
            kind = newKind
            displayItems = Self.applyingKindFilter(items, kind: newKind)
        }
        tracker.track(.mediaLibraryFilterChanged(kind: newKind))
    }

    // MARK: Load (eager)

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        error = nil
        isLoadComplete = false

        await reload()
        do {
            var result = try await collection.refresh()
            await reload()
            while collection.hasMorePages() != false {
                if Task.isCancelled { return }
                let previousTotal = result.totalItems
                result = try await collection.loadNextPage()
                await reload()
                if result.hasMorePages == false || result.totalItems <= previousTotal {
                    break
                }
            }
            if !Task.isCancelled { isLoadComplete = true }
        } catch {
            if !(error is CancellationError), !Task.isCancelled {
                Loggers.mediaLibrary.error("Media library load failed: \(error)")
                self.error = error
            }
        }
    }

    func refresh() async {
        await load()
    }

    // MARK: Data-change observer

    func observe() async {
        let collection = self.collection
        let batches = await client.cache.databaseUpdatesPublisher()
            .filter { @Sendable [weak collection] in
                collection?.isRelevantUpdate(hook: $0) == true
            }
            .collect(.byTime(DispatchQueue.main, .milliseconds(50)))
            .values
        for await _ in batches {
            await reload()
        }
    }

    // MARK: Read helper

    /// Reads the current snapshot from the collection into `items` and
    /// recomputes the derived `displayItems`. SQLite-read errors are logged only.
    private func reload() async {
        do {
            let metadataItems = try await collection.loadItems()
            guard !Task.isCancelled else { return }
            withAnimation {
                items = metadataItems.map(MediaGridItem.init(item:))
                displayItems = Self.applyingKindFilter(items, kind: kind)
            }
        } catch {
            if !(error is CancellationError) {
                Loggers.mediaLibrary.error("Failed to load items: \(error)")
            }
        }
    }
}
