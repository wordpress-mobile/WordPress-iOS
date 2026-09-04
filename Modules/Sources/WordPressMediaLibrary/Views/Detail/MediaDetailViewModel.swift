import Foundation
import SwiftUI
import UIKit
import UniformTypeIdentifiers
import WordPressAPI
import WordPressAPIInternal
import WordPressCore

@MainActor
final class MediaDetailViewModel: ObservableObject {
    @Published private(set) var display: MediaDetailDisplayModel
    @Published private(set) var pendingValues: [MediaEditableField: String] = [:]
    @Published private(set) var inFlightSaveFields: Set<MediaEditableField> = []
    @Published private(set) var isDeleting: Bool = false
    @Published private(set) var isSharing: Bool = false
    @Published var saveErrorMessage: String?
    @Published var deleteErrorMessage: String?
    @Published var shareErrorMessage: String?
    /// Cleanup chokepoint: whatever payload leaves this slot gets its temp
    /// files released. Every dismissal path nils (or replaces) the property,
    /// including the one that bypasses the activity controller entirely: an
    /// interactive swipe-dismiss tears down the SwiftUI sheet without firing
    /// `completionWithItemsHandler`, so no completion-side cleanup can run.
    @Published var sharePayload: SharePayload? {
        didSet {
            if let oldValue, oldValue.id != sharePayload?.id {
                oldValue.cleanupTemporaryFiles()
            }
            isSharePayloadPresented = false
        }
    }
    /// True once the activity sheet for the current `sharePayload` has
    /// actually appeared. Any reassignment of `sharePayload` resets it.
    /// `viewDidDisappear()` uses it to tell an un-presented payload (safe
    /// to release) from one an active activity sheet is still using.
    private var isSharePayloadPresented = false
    @Published private(set) var shouldPop: Bool = false

    let capabilities: MediaLibraryCapabilities

    private let client: WordPressClient
    private let shareService: any MediaDetailShareService
    private let tracker: any MediaTracker
    private let urlOpener: any MediaDetailURLOpener
    private let navigator: any MediaDetailNavigator

    private var didFireOpen = false
    private var inFlightSaveTask: [MediaEditableField: Task<Void, Never>] = [:]
    private var shareTask: Task<Void, Never>?

    /// Payload presented in `UIActivityViewController`. `cleanup` is the
    /// service-supplied closure that removes the temp scope owning `urls`;
    /// `cleanupTemporaryFiles()` invokes it iff non-nil. Ownership is
    /// explicit — never inferred from URL paths — so a custom share service
    /// that returns URLs from outside its own scope cannot accidentally
    /// trigger deletion.
    struct SharePayload: Identifiable {
        let id = UUID()
        let urls: [URL]
        private let cleanup: (@Sendable () -> Void)?

        init(urls: [URL], cleanup: (@Sendable () -> Void)? = nil) {
            self.urls = urls
            self.cleanup = cleanup
        }

        func cleanupTemporaryFiles() {
            cleanup?()
        }
    }

    init(
        media: MediaWithEditContext,
        client: WordPressClient,
        tracker: any MediaTracker,
        urlOpener: any MediaDetailURLOpener,
        shareService: any MediaDetailShareService,
        navigator: any MediaDetailNavigator,
        capabilities: MediaLibraryCapabilities
    ) {
        self.display = MediaDetailDisplayModel(media: media)
        self.client = client
        self.shareService = shareService
        self.tracker = tracker
        self.urlOpener = urlOpener
        self.navigator = navigator
        self.capabilities = capabilities
    }

    /// Bridges the per-field push into UIKit navigation. `MediaDetailView`
    /// is hosted on the outer `UINavigationController` via
    /// `UIHostingController`; SwiftUI `NavigationLink` requires a
    /// `NavigationStack` ancestor, which we deliberately don't have (it
    /// double-stacks with the outer UIKit nav bar). Pushing a fresh
    /// `UIHostingController(rootView: MediaFieldEditorView)` integrates
    /// with the outer nav controller cleanly.
    func pushFieldEditor(for field: MediaEditableField) {
        // The row renders non-tappable when the field isn't editable; bail
        // defensively if a stale tap races past the UI gate (e.g. a delete
        // started between the render and the tap).
        guard isEditable(field) else { return }
        let editor = MediaFieldEditorView(
            field: field,
            value: displayValue(for: field),
            onCommit: { [weak self] newValue in
                self?.commitField(field, value: newValue)
            }
        )
        let host = UIHostingController(rootView: editor)
        host.navigationItem.largeTitleDisplayMode = .never
        navigator.push(host)
    }

    func onAppear() {
        guard !didFireOpen else { return }
        didFireOpen = true
        tracker.track(.mediaLibraryPreviewedItem)
    }

    func displayValue(for field: MediaEditableField) -> String {
        pendingValues[field] ?? field.value(in: display)
    }

    var visibleEditableFields: [MediaEditableField] {
        var fields: [MediaEditableField] = [.title, .caption, .description]
        if showsAltText { fields.append(.altText) }
        return fields
    }

    private var showsAltText: Bool {
        capabilities.supportsAltEditing && display.mimeType.hasPrefix("image/")
    }

    func commitField(_ field: MediaEditableField, value: String) {
        // Skip work when the value didn't change.
        guard value != displayValue(for: field) else { return }
        // Row is disabled while a save is in flight; bail defensively if
        // a stale tap races past the UI gate.
        guard inFlightSaveTask[field] == nil else { return }

        pendingValues[field] = value
        startSave(field: field, value: value)
    }

    private func startSave(field: MediaEditableField, value: String) {
        inFlightSaveFields.insert(field)
        let task: Task<Void, Never> = Task { [weak self] in
            await self?.performSave(field: field, value: value)
        }
        inFlightSaveTask[field] = task
    }

    private func performSave(field: MediaEditableField, value: String) async {
        let params = Self.makeUpdateParams(field: field, value: value)
        let outcome: Result<MediaWithEditContext, Error>
        do {
            let service = try await client.service
            let server = try await service.media().updateMedia(mediaId: MediaId(display.id), params: params)
            outcome = .success(server)
        } catch {
            outcome = .failure(error)
        }

        await MainActor.run {
            self.applyOutcome(field: field, outcome: outcome)
        }
    }

    private func applyOutcome(field: MediaEditableField, outcome: Result<MediaWithEditContext, Error>) {
        var lastError: String?
        switch outcome {
        case .success(let server):
            self.display.apply(field, fromServer: server)
            self.tracker.track(.mediaLibraryEditedItemMetadata)
        case .failure(let error):
            Loggers.mediaLibrary.error("Metadata save failed for field \(field): \(error)")
            lastError = error.localizedDescription
        }

        // The cache-aware `updateMedia` call upserts the server response into
        // the wordpress-rs cache and fires `notify_collections`, so any live
        // `MediaMetadataCollection` (e.g. the grid VM's) refreshes its
        // membership without us nudging it.
        inFlightSaveTask[field] = nil
        inFlightSaveFields.remove(field)
        pendingValues[field] = nil

        if let lastError {
            saveErrorMessage = lastError
        }
    }

    var isMetadataEditingEnabled: Bool {
        capabilities.supportsMetadataEditing && !isDeleting && !isSharing && !shouldPop
    }

    func isEditable(_ field: MediaEditableField) -> Bool {
        isMetadataEditingEnabled && !inFlightSaveFields.contains(field)
    }

    var isTrashEnabled: Bool {
        capabilities.supportsDeletion && !isAnyOperationInFlight
    }

    var isAnyOperationInFlight: Bool {
        !inFlightSaveFields.isEmpty || isDeleting || isSharing || shouldPop
    }

    var isShareEnabled: Bool {
        !isAnyOperationInFlight && !display.sourceUrl.isEmpty
    }

    func share() {
        guard isShareEnabled, shareTask == nil else { return }
        isSharing = true
        tracker.track(.siteMediaShareTapped(count: 1))
        guard let item = makeShareItem() else {
            isSharing = false
            shareErrorMessage = Strings.detailShareErrorInvalidURL
            return
        }
        shareTask = Task { [weak self] in
            guard let self else { return }
            await self.performShare(item: item)
            self.shareTask = nil
        }
    }

    /// Cancels the in-flight share download, if any. Wired to the progress
    /// spinner in the toolbar and to the screen's disappearance.
    func cancelShare() {
        shareTask?.cancel()
    }

    /// Marks the current `sharePayload` as presented. Wired to the activity
    /// sheet content's appearance.
    func shareSheetDidPresent() {
        isSharePayloadPresented = true
    }

    /// Screen-teardown hook. Cancels an in-flight download, and releases a
    /// payload whose activity sheet never presented: when the download
    /// finishes just as the screen pops, `performShare` assigns
    /// `sharePayload` before `onDisappear` fires, and without this pass no
    /// code path would ever invoke that payload's cleanup closure. A payload
    /// whose sheet is up (e.g. the screen left the window because of a tab
    /// switch) is left alone; the sheet's completion handler owns it.
    func viewDidDisappear() {
        cancelShare()
        if sharePayload != nil, !isSharePayloadPresented {
            sharePayload = nil
        }
    }

    private func performShare(item: DownloadableMediaItem) async {
        do {
            let result = try await shareService.downloadForSharing(items: [item])
            if Task.isCancelled {
                // Cancelled between the download finishing and this hop; the
                // payload will never present, so release its files here.
                result.cleanup?()
                isSharing = false
                return
            }
            isSharing = false
            sharePayload = SharePayload(urls: result.urls, cleanup: result.cleanup)
        } catch is CancellationError {
            // User-initiated cancellation is not an error. The adapter
            // removes its batch directory when the download throws.
            isSharing = false
        } catch let error as URLError where error.code == .cancelled {
            // URLSession surfaces task cancellation as URLError(.cancelled).
            isSharing = false
        } catch {
            Loggers.mediaLibrary.error("Media share failed for id \(display.id): \(error)")
            isSharing = false
            shareErrorMessage = error.localizedDescription
        }
    }

    /// Called from the activity controller's `completionWithItemsHandler`.
    /// Takes the payload the sheet actually presented (captured by the sheet
    /// content closure) so a swipe-dismiss that nils the published binding
    /// first can't make the identity check match a different payload. The
    /// actual temp-file release happens in `sharePayload`'s `didSet`.
    func reportShareDismissed(_ payload: SharePayload, completed: Bool) {
        if sharePayload?.id == payload.id {
            sharePayload = nil
        }
        if completed {
            tracker.track(.mediaLibrarySharedItemLink)
        }
    }

    private func makeShareItem() -> DownloadableMediaItem? {
        guard let url = URL(string: display.sourceUrl) else { return nil }
        return DownloadableMediaItem(
            sourceUrl: url,
            mimeType: display.mimeType,
            suggestedFilename: MediaShareFilename.suggested(
                title: display.title,
                slug: display.slug,
                sourceUrl: display.sourceUrl,
                id: display.id
            )
        )
    }

    func delete() async {
        guard !isAnyOperationInFlight else { return }
        isDeleting = true
        do {
            let service = try await client.service
            _ = try await service.media().deleteMediaPermanently(mediaId: MediaId(display.id))
            tracker.track(.mediaLibraryDeletedItems(count: 1))
            // `shouldPop` joins the in-flight gates, so flipping it before
            // resetting `isDeleting` keeps every affordance disabled through
            // the pop animation.
            shouldPop = true
            isDeleting = false
        } catch {
            Loggers.mediaLibrary.error("Media delete failed for id \(display.id): \(error)")
            deleteErrorMessage = error.localizedDescription
            isDeleting = false
        }
    }

    func openSourceURL() {
        // Pushing the web view during an in-flight delete would let the
        // delete's pop remove the web view instead of this screen, stranding
        // a detail view for an item that no longer exists.
        guard !isAnyOperationInFlight else { return }
        guard let url = URL(string: display.sourceUrl), !display.sourceUrl.isEmpty else { return }
        urlOpener.open(url, mediaTitle: display.title)
    }

    private static func makeUpdateParams(field: MediaEditableField, value: String) -> MediaUpdateParams {
        switch field {
        case .title: return MediaUpdateParams(title: value)
        case .caption: return MediaUpdateParams(caption: value)
        case .description: return MediaUpdateParams(description: value)
        case .altText: return MediaUpdateParams(altText: value)
        }
    }
}
