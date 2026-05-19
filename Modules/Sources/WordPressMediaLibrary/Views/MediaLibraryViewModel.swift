import Combine
import Foundation
import SwiftUI
import WordPressAPI
import WordPressAPIInternal
import WordPressCore

/// App-target switches that gate which detail screen affordances are
/// available. Public so app-side routing can populate it without going
/// through the (internal) view model type.
public struct MediaLibraryCapabilities: Equatable {
    public let supportsAltEditing: Bool
    public let supportsMetadataEditing: Bool
    public let supportsDeletion: Bool

    public init(
        supportsAltEditing: Bool,
        supportsMetadataEditing: Bool,
        supportsDeletion: Bool
    ) {
        self.supportsAltEditing = supportsAltEditing
        self.supportsMetadataEditing = supportsMetadataEditing
        self.supportsDeletion = supportsDeletion
    }
}

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
    let uploader: MediaUploader?
    let urlOpener: (any MediaDetailURLOpener)?
    let shareService: (any MediaDetailShareService)?
    let detailNavigator: (any MediaDetailNavigator)?
    let detailCapabilities: MediaLibraryCapabilities?

    /// Caches the most-recent `MediaWithEditContext` per item id so
    /// `makeDetailVM(for:)` can hand the detail screen a fully-resolved
    /// payload without re-fetching. Rebuilt on every `loadItems` snapshot.
    private var resolvedMediaByID: [Int64: MediaWithEditContext] = [:]

    @Published private(set) var bannerSummary: BannerSummary?
    @Published private(set) var uploadsScreenItems: [UploadRowItem] = []

    private var uploaderObserverTask: Task<Void, Never>?

    struct BannerSummary: Equatable {
        let pendingCount: Int
        let failedCount: Int
    }

    struct UploadRowItem: Identifiable, Equatable {
        enum Mode: Equatable {
            case uploading(Progress)
            case failed(message: String, isRetryable: Bool)
        }
        let id: UUID
        let displayName: String
        let kind: MediaKind
        let localFileURL: URL?
        let mode: Mode
    }

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
    /// `observe()` can subscribe to the local cache's update stream. The
    /// `uploader` and detail wiring are passed only for the library instance;
    /// search instances leave them nil and never surface the upload banner,
    /// the queue, or the cell-tap detail push.
    init(
        service: WpService,
        client: WordPressClient,
        tracker: any MediaTracker,
        search: String? = nil,
        uploader: MediaUploader? = nil,
        urlOpener: (any MediaDetailURLOpener)? = nil,
        shareService: (any MediaDetailShareService)? = nil,
        navigator: (any MediaDetailNavigator)? = nil,
        capabilities: MediaLibraryCapabilities? = nil
    ) {
        self.tracker = tracker
        self.client = client
        self.collection = service.media()
            .createMediaMetadataCollectionWithEditContext(
                filter: MediaListFilter(search: search, mediaType: nil),
                perPage: 100
            )
        self.uploader = uploader
        self.urlOpener = urlOpener
        self.shareService = shareService
        self.detailNavigator = navigator
        self.detailCapabilities = capabilities
        startUploaderObserver()
    }

    /// Subscribes weakly so a navigated-away view model deallocates instead
    /// of being kept alive by the stream loop. The publisher replays the
    /// current snapshot to the new subscriber before emitting transitions.
    private func startUploaderObserver() {
        guard let uploader else { return }
        let publisher = uploader.statePublisher
        uploaderObserverTask = Task { [weak self] in
            for await state in publisher.values {
                guard !Task.isCancelled else { return }
                guard let self else { return }
                self.applyUploaderState(state)
            }
        }
    }

    deinit {
        uploaderObserverTask?.cancel()
    }

    @MainActor
    private func applyUploaderState(_ state: UploaderState) {
        if state.isEmpty {
            bannerSummary = nil
        } else {
            bannerSummary = BannerSummary(
                pendingCount: state.pendingCount,
                failedCount: state.failedCount
            )
        }
        // `state.entries` preserves submission order across pending/failed
        // transitions, so the Uploads-screen row stays put when an
        // in-flight upload fails (or a failed row is retried).
        uploadsScreenItems = state.entries.map { entry in
            switch entry {
            case .pending(let p):
                return UploadRowItem(
                    id: p.id,
                    displayName: p.displayName,
                    kind: p.kind,
                    localFileURL: p.localFileURL,
                    mode: .uploading(p.progress)
                )
            case .failed(let f):
                return UploadRowItem(
                    id: f.id,
                    displayName: f.displayName,
                    kind: f.kind,
                    localFileURL: f.localFileURL,
                    mode: .failed(message: f.errorMessage, isRetryable: f.isRetryable)
                )
            }
        }
    }

    func enqueue(sources: [UploadSource]) async {
        guard let uploader else { return }
        for source in sources {
            let resolvedSource = analyticsSourceFor(source: source)
            tracker.track(.mediaLibraryAdded(source: resolvedSource, kind: source.estimatedKind))
        }
        await uploader.enqueue(sources: sources)
    }

    func cancelUpload(_ id: UUID) async {
        await uploader?.cancel(id)
    }

    func retryUpload(_ id: UUID) async {
        guard let uploader else { return }
        tracker.track(.mediaLibraryUploadRetried)
        await uploader.retry(id)
    }

    func removeUpload(_ id: UUID) async {
        await uploader?.remove(id)
    }

    func cancelAllUploads() async { await uploader?.cancelAllPending() }

    func retryAllUploads() async {
        guard let uploader else { return }
        let retryable = uploadsScreenItems.contains { row in
            if case .failed(_, let isRetryable) = row.mode { return isRetryable }
            return false
        }
        guard retryable else { return }
        tracker.track(.mediaLibraryUploadRetried)
        await uploader.retryAllFailed()
    }

    func removeAllFailedUploads() async { await uploader?.removeAllFailed() }

    private func analyticsSourceFor(source: UploadSource) -> MediaUploadSource {
        switch source {
        case .photoLibrary: return .photoLibrary
        case .cameraImage, .cameraVideo: return .camera
        case .file: return .otherApps
        case .imagePlayground: return .imagePlayground
        case .remoteURL:
            // Stock Photos is the only external picker that produces .remoteURL.
            return .stockPhotos
        }
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
            // Rebuild the resolved-media side store from this batch so
            // `makeDetailVM(for:)` can hand the detail screen a fully-
            // hydrated payload without re-fetching.
            var resolved: [Int64: MediaWithEditContext] = [:]
            for item in metadataItems {
                if let media = item.resolvedMedia { resolved[item.id] = media }
            }
            self.resolvedMediaByID = resolved
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

    // MARK: Detail navigation

    /// Cheap check for whether the cell should render as tappable.
    /// Mirrors the early-out conditions in `makeDetailVM(for:)` without
    /// constructing the throwaway detail VM on every cell render.
    func canOpenDetail(for item: MediaGridItem) -> Bool {
        detailNavigator != nil && resolvedMediaByID[item.id] != nil
    }

    /// Builds a `MediaDetailViewModel` for the tapped cell. Returns nil when
    /// the cell carries no resolvable payload (placeholder states), or when the
    /// instance has no detail wiring (e.g. a search-results grid).
    func makeDetailVM(for item: MediaGridItem) -> MediaDetailViewModel? {
        guard let urlOpener,
            let shareService,
            let detailNavigator,
            let detailCapabilities,
            let media = resolvedMediaByID[item.id]
        else { return nil }
        return MediaDetailViewModel(
            media: media,
            client: client,
            tracker: tracker,
            urlOpener: urlOpener,
            shareService: shareService,
            navigator: detailNavigator,
            capabilities: detailCapabilities
        )
    }
}

extension MediaLibraryViewModel: ExternalMediaPickerDelegate {
    func didPick(remoteMedia: [ExternalRemoteMedia]) {
        let sources = remoteMedia.map { media in
            UploadSource.remoteURL(
                UploadSource.RemoteURL(
                    url: media.url,
                    suggestedName: media.suggestedName,
                    contentType: media.contentType,
                    caption: media.caption
                )
            )
        }
        Task { await self.enqueue(sources: sources) }
    }

    func didPick(imagePlaygroundFile url: URL, suggestedName: String) {
        Task {
            await self.enqueue(sources: [.imagePlayground(url, suggestedName: suggestedName)])
        }
    }

    func didCancel() {
        // No-op today; hook exists for future analytics if needed.
    }
}
