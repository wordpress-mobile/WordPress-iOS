import Combine
import Foundation
import OrderedCollections
import SwiftUI
import WordPressAPI
import WordPressAPIInternal
import WordPressCore

/// App-target switches that gate which detail screen affordances are
/// available. Public so app-side routing can populate it without going
/// through the (internal) view model type.
public struct MediaLibraryCapabilities: Equatable, Sendable {
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

    // MARK: - Selection state (M5)

    @Published private(set) var isSelectionModeActive: Bool = false

    /// Insertion-ordered set of selected media ids. Read by the view for
    /// badge state, by `selectionToolbarTitle`, and by the bulk-action
    /// methods. Iteration order is consumed by bulk share to preserve the
    /// user's tap order when assembling the activity items.
    @Published private(set) var selectedIDs = OrderedSet<Int64>()

    /// In-flight delete markers, dims + spinners + disables hit testing
    /// on the corresponding cells. Cleared inside `performDelete`'s `defer`
    /// (both success and failure paths) for pagination safety.
    @Published private(set) var pendingDeleteIDs: Set<Int64> = []

    /// Identity for the currently-active bulk-share download, which runs in
    /// the VM-owned `bulkShareTask` so it survives the view leaving the
    /// window (e.g. a tab switch); `exitSelectionMode()` cancels it
    /// explicitly. The preparing-vs-idle UI state is derived from this (see
    /// `isPreparingBulkShare`), so the two can never drift out of lockstep.
    @Published private(set) var bulkShareRequest: BulkShareRequest?

    /// Owns the bulk-share download so its lifetime is the view model's,
    /// not the view's; a view-lifetime `.task` would be cancelled by any
    /// disappearance and silently drop the preparation.
    private var bulkShareTask: Task<Void, Never>?

    /// True while a bulk-share download is in flight. Derived from
    /// `bulkShareRequest` so there is a single source of truth.
    var isPreparingBulkShare: Bool { bulkShareRequest != nil }

    /// Activity-sheet payload. Set by `performBulkShare` on success;
    /// presented via `.sheet(item:)`. Nilled in `reportShareDismissed` or
    /// `exitSelectionMode`. Cleanup chokepoint: whatever payload leaves this
    /// slot gets its temp files released. Every dismissal path nils (or
    /// replaces) the property, including the one that bypasses the activity
    /// controller entirely: an interactive swipe-dismiss tears down the
    /// SwiftUI sheet without firing `completionWithItemsHandler`, so no
    /// completion-side cleanup can run.
    @Published var sharePayload: MediaDetailViewModel.SharePayload? {
        didSet {
            if let oldValue, oldValue.id != sharePayload?.id {
                oldValue.cleanupTemporaryFiles()
            }
        }
    }

    /// Bulk-delete failure message, presented as an alert. Set when the
    /// confirmed delete fails wholesale or partially; cleared by the view.
    @Published var bulkDeleteErrorMessage: String?

    /// Bulk-share failure message, presented as an alert. Set when the share
    /// download fails or no selected item can be prepared; cleared by the view.
    @Published var bulkShareErrorMessage: String?

    /// Toggle-time payload snapshot, keyed by media id. Survives
    /// `loadItems` rebuilds of `resolvedMediaByID`, so a selection that
    /// spans pages remains shareable after a page-1 refresh. Not
    /// `@Published`; the view never reads it directly. Bulk-share-item
    /// construction reads it.
    private var selectedMediaSnapshots: [Int64: MediaWithEditContext] = [:]

    /// V1 parity title: five variants for empty / image-singular / image-plural
    /// / item-singular / item-plural. Reads `selectedMediaSnapshots` for the
    /// image-vs-mixed decision so the lookup is cheap and survives refresh.
    var selectionToolbarTitle: String {
        let count = selectedIDs.count
        if count == 0 { return Strings.selectionTitleEmpty }
        if allSelectedAreImages {
            let template = count == 1 ? Strings.selectionTitleImageSingular : Strings.selectionTitleImagePlural
            return String.localizedStringWithFormat(template, count)
        }
        let template = count == 1 ? Strings.selectionTitleItemSingular : Strings.selectionTitleItemPlural
        return String.localizedStringWithFormat(template, count)
    }

    private var allSelectedAreImages: Bool {
        guard !selectedIDs.isEmpty else { return false }
        return selectedIDs.allSatisfy { id in
            selectedMediaSnapshots[id]?.mimeType.hasPrefix("image/") == true
        }
    }

    struct BulkShareRequest: Identifiable {
        let id = UUID()
        let items: [DownloadableMediaItem]
    }

    /// Serializes loads: `load()` waits for an in-flight (possibly cancelled
    /// and still-unwinding) load to finish before starting, because each
    /// instance owns one collection.
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
    /// leave it nil and never surface the upload banner or queue. The detail
    /// wiring is passed for both, so search results can push detail too.
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
        if isSelectionModeActive {
            exitSelectionMode()
        }
        withAnimation {
            kind = newKind
            displayItems = Self.applyingKindFilter(items, kind: newKind)
        }
        tracker.track(.mediaLibraryFilterChanged(kind: newKind))
    }

    // MARK: - Selection mode (M5)

    func enterSelectionMode() {
        isSelectionModeActive = true
    }

    func exitSelectionMode() {
        // Cancel the in-flight bulk-share download and nil bulkShareRequest
        // (which also flips isPreparingBulkShare back to false). Nils
        // sharePayload too, closing the race where downloads finish and the
        // activity sheet is about to present when the user taps Done.
        bulkShareTask?.cancel()
        bulkShareTask = nil
        bulkShareRequest = nil
        sharePayload = nil
        isSelectionModeActive = false
        selectedIDs.removeAll()
        selectedMediaSnapshots.removeAll()
    }

    /// Toggles the item's id in `selectedIDs` and captures/clears its
    /// payload snapshot in `selectedMediaSnapshots`. No-op for items where
    /// `canOpenDetail` returns false (placeholders, error rows without
    /// cached payload). Reads `resolvedMediaByID[item.id]` for the snapshot
    /// payload at toggle time; that payload then survives subsequent
    /// refreshes / pagination changes that mutate `resolvedMediaByID`.
    func toggleSelection(for item: MediaGridItem) {
        guard canOpenDetail(for: item) else { return }
        guard let media = resolvedMediaByID[item.id] else { return }
        if selectedIDs.contains(item.id) {
            selectedIDs.remove(item.id)
            selectedMediaSnapshots[item.id] = nil
        } else {
            selectedIDs.append(item.id)
            selectedMediaSnapshots[item.id] = media
        }
    }

    // MARK: - Bulk delete (M5)

    /// Fire-and-forget bulk delete. Selection mode exits immediately on
    /// confirm; per-cell dim+spinner indicates in-flight deletes. Both
    /// success and failure clear the pending marker in `performDelete`'s
    /// `defer` (both success and failure paths) for pagination safety. A
    /// wholesale or partial failure surfaces `bulkDeleteErrorMessage` (the
    /// detail screen has an equivalent delete-failure alert).
    func confirmBulkDelete() async {
        let ids = Array(selectedIDs)
        guard !ids.isEmpty else { return }

        pendingDeleteIDs.formUnion(ids)
        exitSelectionMode()

        let service: WpService
        do {
            service = try await client.service
        } catch {
            Loggers.mediaLibrary.error("Bulk delete: client resolve failed: \(error)")
            pendingDeleteIDs.subtract(ids)
            bulkDeleteErrorMessage = Strings.selectionDeleteFailedMessage
            return
        }

        let successCount = await withTaskGroup(of: Bool.self) { group in
            let maxConcurrent = 3
            var iterator = ids.makeIterator()

            func submit(_ id: Int64) {
                group.addTask { [weak self] in
                    await self?.performDelete(id: id, service: service) ?? false
                }
            }
            for _ in 0..<maxConcurrent {
                if let id = iterator.next() { submit(id) }
            }

            var successes = 0
            while let didSucceed = await group.next() {
                if didSucceed { successes += 1 }
                if let id = iterator.next() { submit(id) }
            }
            return successes
        }

        if successCount > 0 {
            tracker.track(.mediaLibraryDeletedItems(count: successCount))
        }
        if successCount < ids.count {
            bulkDeleteErrorMessage = Strings.selectionDeleteFailedMessage
        }
    }

    /// One delete attempt. Returns `true` on success. `defer` clears the
    /// pending marker on both paths synchronously. `MediaLibraryViewModel`
    /// is `@MainActor`, so direct mutation is safe; no nested Task is needed.
    private func performDelete(id: Int64, service: WpService) async -> Bool {
        defer { pendingDeleteIDs.remove(id) }
        do {
            _ = try await service.media().deleteMediaPermanently(mediaId: MediaId(id))
            return true
        } catch {
            Loggers.mediaLibrary.error("Bulk delete failed for id \(id): \(error)")
            return false
        }
    }

    // MARK: - Bulk share (M5)

    /// Starts a bulk-share preparation. Builds `DownloadableMediaItem`s
    /// from `selectedMediaSnapshots` (NOT `resolvedMediaByID`, the snapshot
    /// map survives refresh and pagination). Preflight keeps only items with
    /// an absolute http/https URL with a host. Fires
    /// `.siteMediaShareTapped(count:)` before the download starts, using the
    /// actually-prepared count.
    func startBulkShare() {
        guard !selectedIDs.isEmpty, !isPreparingBulkShare else { return }
        let ids = Array(selectedIDs)
        let items: [DownloadableMediaItem] = ids.compactMap { id in
            guard let media = selectedMediaSnapshots[id],
                let url = URL(string: media.sourceUrl),
                let scheme = url.scheme?.lowercased(),
                scheme == "http" || scheme == "https",
                url.host?.isEmpty == false
            else { return nil }
            return DownloadableMediaItem(
                sourceUrl: url,
                mimeType: media.mimeType,
                suggestedFilename: MediaShareFilename.suggested(for: media)
            )
        }

        // When no selected item yields a shareable URL the tap would otherwise
        // do nothing (no spinner, no sheet); surface an alert instead. A partial
        // drop still proceeds: the activity sheet shows the prepared subset, which
        // is its own feedback.
        guard !items.isEmpty else {
            Loggers.mediaLibrary.warning(
                "Bulk share: tap produced 0 preparable items from \(ids.count) selected ids"
            )
            bulkShareErrorMessage = Strings.selectionShareNothingMessage
            return
        }

        if items.count != ids.count {
            Loggers.mediaLibrary.warning(
                "Bulk share: \(ids.count - items.count) selected items dropped (missing snapshot or unparseable sourceUrl); proceeding with \(items.count)"
            )
        }
        tracker.track(.siteMediaShareTapped(count: items.count))
        let request = BulkShareRequest(items: items)
        bulkShareRequest = request
        // The handle is deliberately not cleared on completion: a stale
        // task's trailing write could clobber a newer task's handle and
        // leave it uncancellable, while a finished task kept around is
        // inert (cancelling it is a no-op). The next share or exit
        // overwrites it.
        bulkShareTask = Task { [weak self] in
            await self?.performBulkShare(request)
        }
    }

    /// Runs the bulk-share download inside the VM-owned `bulkShareTask`;
    /// `exitSelectionMode()` cancels it. Cleanup and `sharePayload`
    /// publication are request-id-scoped: a stale cancelled task that
    /// unwinds after a newer request started will NOT clobber the newer
    /// request's state.
    private func performBulkShare(_ request: BulkShareRequest) async {
        defer {
            if bulkShareRequest?.id == request.id {
                bulkShareRequest = nil
            }
        }
        guard let shareService else { return }
        do {
            let result = try await shareService.downloadForSharing(items: request.items)
            do {
                try Task.checkCancellation()
            } catch {
                result.cleanup?()
                throw error
            }
            guard bulkShareRequest?.id == request.id else {
                result.cleanup?()
                return
            }
            sharePayload = .init(urls: result.urls, cleanup: result.cleanup)
        } catch is CancellationError {
            // expected, Done cancelled mid-download
        } catch let urlError as URLError where urlError.code == .cancelled {
            // URLSession surfaces cancellation as URLError(.cancelled), not CancellationError
        } catch {
            // The download is an atomic batch (one failure discards the whole
            // batch dir), so surface the failure instead of silently reverting
            // the spinner to the share icon, mirroring the detail screen's
            // share-failure alert.
            Loggers.mediaLibrary.error("Bulk share download failed: \(error)")
            if bulkShareRequest?.id == request.id {
                bulkShareErrorMessage = error.localizedDescription
            }
        }
    }

    /// Called from the activity controller's `completionWithItemsHandler`.
    /// Takes the payload the sheet actually presented (captured by the sheet
    /// content closure) so a swipe-dismiss that nils the published binding
    /// first can't make the identity check match a different payload. The
    /// actual temp-file release happens in `sharePayload`'s `didSet`.
    /// V1 bulk parity: completed share exits selection mode; cancelled
    /// activity sheet keeps selection intact for retry. Neither path fires
    /// `.mediaLibrarySharedItemLink`; that event is V1-single-item only.
    func reportShareDismissed(_ payload: MediaDetailViewModel.SharePayload, completed: Bool) {
        if sharePayload?.id == payload.id {
            sharePayload = nil
        }
        if completed {
            exitSelectionMode()
        }
    }

    func isSelected(_ item: MediaGridItem) -> Bool {
        selectedIDs.contains(item.id)
    }

    // MARK: Load (eager)

    func load() async {
        // A cancelled predecessor may still be unwinding (its defer hasn't
        // reset `isLoading` yet) when a replacement load starts; wait for it
        // instead of dropping this call, so a task restart can't strand the
        // library half-loaded with `isLoadComplete` stuck false.
        while isLoading {
            if Task.isCancelled { return }
            try? await Task.sleep(for: .milliseconds(20))
        }
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
            if !Task.isCancelled {
                isLoadComplete = true
                // Now that every page is loaded, drop any selection that points
                // at an item the server no longer returns (e.g. deleted from
                // another device). reload()'s own reconcile is a no-op until this
                // flag flips, so the final pass has to happen here.
                reconcileSelection()
            }
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
            reconcileSelection()
        } catch {
            if !(error is CancellationError) {
                Loggers.mediaLibrary.error("Failed to load items: \(error)")
            }
        }
    }

    /// Drops any selected id (and its share snapshot) that the loaded item set
    /// no longer contains, so the toolbar count can't strand a ghost the user
    /// can't deselect and bulk share can't 404 on a deleted item's stale URL.
    /// Guarded on `isLoadComplete`: during initial load / pagination `items`
    /// holds only a partial set, and pruning there would drop a legitimate
    /// selection on a not-yet-loaded page (the share snapshot deliberately
    /// survives pagination). Once every page is loaded, an absent id is a real
    /// deletion.
    private func reconcileSelection() {
        guard isLoadComplete, !selectedIDs.isEmpty else { return }
        let liveIDs = Set(items.map(\.id))
        let staleIDs = selectedIDs.filter { !liveIDs.contains($0) }
        guard !staleIDs.isEmpty else { return }
        for id in staleIDs {
            selectedIDs.remove(id)
            selectedMediaSnapshots[id] = nil
        }
    }

    // MARK: Detail navigation

    /// Cheap check for whether the cell should render as tappable. Mirrors
    /// the early-out conditions in `makeDetailVM(for:)` without
    /// constructing the throwaway detail VM on every cell render.
    func canOpenDetail(for item: MediaGridItem) -> Bool {
        detailNavigator != nil && resolvedMediaByID[item.id] != nil
    }

    /// Whether Select should be enabled. Evaluated over `displayItems` (the
    /// kind-filtered grid the user actually sees), not the unfiltered `items`,
    /// so Select can't enter selection mode over an empty filtered grid. The
    /// `contains` short-circuits on the first openable item.
    var canEnterSelectionMode: Bool {
        displayItems.contains { canOpenDetail(for: $0) }
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
