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
    let uploader: MediaUploader?

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
    /// `uploader` is wired only for the library instance; search instances
    /// leave it nil and never surface the upload banner or queue.
    init(
        service: WpService,
        client: WordPressClient,
        tracker: any MediaTracker,
        search: String? = nil,
        uploader: MediaUploader? = nil
    ) {
        self.tracker = tracker
        self.client = client
        self.collection = service.media()
            .createMediaMetadataCollectionWithEditContext(
                filter: MediaListFilter(search: search, mediaType: nil),
                perPage: 100
            )
        self.uploader = uploader
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

    func dismissUpload(_ id: UUID) async {
        await uploader?.dismiss(id)
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

    func dismissAllUploads() async { await uploader?.dismissAllFailed() }

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
