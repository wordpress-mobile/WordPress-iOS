@preconcurrency import Combine
import Foundation
import OrderedCollections
import UniformTypeIdentifiers
import WordPressAPI
import WordPressCore
import os

public actor MediaUploader {
    /// UTTypes the document picker offers. Lock-backed rather than actor
    /// state so SwiftUI can read it synchronously; refreshed by
    /// `updatePolicy(_:)`.
    nonisolated var filePickerContentTypes: [UTType] {
        _filePickerContentTypes.withLock { $0 }
    }
    private nonisolated let _filePickerContentTypes: OSAllocatedUnfairLock<[UTType]>

    private let transport: any MediaUploadTransport
    private var materializer: any MediaSourceMaterializing

    /// Multicasts state to every observer and replays the latest snapshot
    /// to new subscribers, so a re-pushed Media Library screen sees the
    /// in-flight state immediately.
    private nonisolated let stateSubject = CurrentValueSubject<UploaderState, Never>(
        UploaderState(entries: [])
    )

    /// Every in-flight or failed upload, keyed by id and held in submission
    /// order. The `InternalEntry` case encodes pending-vs-failed, so an id is
    /// in exactly one state and can never be orphaned. In-flight to failed
    /// (and failed to pending via Retry) updates the value in place,
    /// preserving its slot so the Uploads screen does not reshuffle.
    /// `didSet` is the single emit point, and every operation mutates the
    /// dictionary exactly once, so one action publishes one snapshot.
    private var entries: OrderedDictionary<UUID, InternalEntry> = [:] {
        didSet { stateSubject.send(snapshot()) }
    }

    /// Set once by `tearDown()`. New work is refused afterwards: the state
    /// subject has already completed, so anything enqueued later would
    /// upload invisibly with no way to observe or cancel it.
    private var isTornDown = false

    public init(
        client: WordPressClient,
        policy: MediaUploadPolicy
    ) {
        self.init(
            transport: DefaultMediaUploadTransport(client: client),
            policy: policy
        )
    }

    init(
        transport: any MediaUploadTransport,
        policy: MediaUploadPolicy
    ) {
        self.transport = transport
        self.materializer = UploadSourceMaterializer(policy: policy)
        self._filePickerContentTypes = OSAllocatedUnfairLock(
            initialState: policy.filePickerContentTypes
        )
    }

    /// Module-internal test seam.
    init(
        transport: any MediaUploadTransport,
        materializer: any MediaSourceMaterializing,
        filePickerContentTypes: [UTType] = [.content]
    ) {
        self.transport = transport
        self.materializer = materializer
        self._filePickerContentTypes = OSAllocatedUnfairLock(
            initialState: filePickerContentTypes
        )
    }

    deinit {
        // Safety net for an owner that drops the uploader without calling
        // tearDown(): stop in-flight work and complete the subject so
        // `statePublisher.values` iterations terminate instead of suspending
        // forever. Staged files are reclaimed by the next-launch sweep.
        for case .pending(let pending) in entries.values {
            pending.task.cancel()
        }
        stateSubject.send(completion: .finished)
    }

    /// Deletes upload staging files orphaned by a crash or force-quit. Call once
    /// at app launch: in-memory uploader state never survives process
    /// termination, so anything still on disk is orphaned.
    public static func sweepOrphanedStagingFiles() {
        UploadSourceMaterializer.sweepOrphanedStagingFiles()
    }

    /// Replays the current snapshot to each new subscriber, then emits every
    /// future transition until the actor tears down. Call sites can iterate
    /// it as an `AsyncSequence` via `statePublisher.values`.
    nonisolated var statePublisher: AnyPublisher<UploaderState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    func snapshot() -> UploaderState {
        UploaderState(entries: entries.values.map { $0.viewModelValue })
    }

    /// Applies a fresh policy to all future enqueues, so user-visible settings
    /// (like stripping GPS locations) take effect without recreating the
    /// uploader and losing in-flight state. In-flight uploads keep the
    /// materializer their work task captured at enqueue time and finish under
    /// the policy that was active when they were enqueued. Retry re-uploads
    /// the already-materialized bytes and never re-consults the policy.
    ///
    /// Replaces the materializer with a default-rooted production one, so do
    /// not call this on a seam-constructed uploader whose test materializer
    /// or staging root must stay injected. Basename dedup in the new
    /// materializer restarts from scratch, which is harmless: a single
    /// enqueue batch always shares one materializer, and the server enforces
    /// final filename uniqueness.
    public func updatePolicy(_ policy: MediaUploadPolicy) {
        materializer = UploadSourceMaterializer(policy: policy)
        _filePickerContentTypes.withLock { $0 = policy.filePickerContentTypes }
    }

    func enqueue(sources: [UploadSource]) {
        guard !isTornDown, !sources.isEmpty else { return }
        var updated = entries
        for source in sources {
            let id = UUID()
            updated[id] = .pending(
                InternalPending(
                    id: id,
                    displayName: sourceDisplayName(source),
                    kind: source.estimatedKind,
                    overallProgress: Progress(totalUnitCount: 100),
                    payload: .unmaterialized(source),
                    task: makeWorkTask(for: id)
                )
            )
        }
        entries = updated
    }

    func cancel(_ uploadID: UUID) {
        guard case .pending(let entry)? = entries[uploadID] else { return }
        entries.removeValue(forKey: uploadID)
        cancelWork(of: entry)
    }

    func retry(_ uploadID: UUID) {
        guard !isTornDown,
            case .failed(let failedEntry)? = entries[uploadID],
            let retryEntry = makeRetryEntry(from: failedEntry)
        else {
            return
        }
        // Overwrite the entry in place so it keeps its slot across the
        // failed to pending retry transition.
        entries[failedEntry.id] = retryEntry
    }

    func remove(_ uploadID: UUID) {
        guard case .failed(let entry)? = entries[uploadID] else { return }
        entries.removeValue(forKey: uploadID)
        Self.removeStagingDirectory(entry.materialized?.stagingDirectory)
    }

    func cancelAllPending() {
        for case .pending(let pending) in entries.values {
            cancelWork(of: pending)
        }
        entries.removeAll {
            if case .pending = $0.value { true } else { false }
        }
    }

    func retryAllFailed() {
        guard !isTornDown else { return }
        var updated = entries
        for (id, entry) in entries {
            guard case .failed(let failedEntry) = entry,
                let retryEntry = makeRetryEntry(from: failedEntry)
            else {
                continue
            }
            updated[id] = retryEntry
        }
        entries = updated
    }

    func removeAllFailed() {
        for case .failed(let failedEntry) in entries.values {
            Self.removeStagingDirectory(failedEntry.materialized?.stagingDirectory)
        }
        entries.removeAll {
            if case .failed = $0.value { true } else { false }
        }
    }

    public func tearDown() {
        isTornDown = true
        for entry in entries.values {
            switch entry {
            case .pending(let pending):
                cancelWork(of: pending)
            case .failed(let failedEntry):
                Self.removeStagingDirectory(failedEntry.materialized?.stagingDirectory)
            }
        }
        entries = [:]
        stateSubject.send(completion: .finished)
    }

    // MARK: - Internals

    private func beginWork(for id: UUID) -> InternalPending? {
        guard case .pending(let entry)? = entries[id] else { return nil }
        return entry
    }

    private func makeWorkTask(for id: UUID) -> Task<Void, Never> {
        Task { [weak self, materializer, transport] in
            do {
                guard let entry = await self?.beginWork(for: id) else { return }
                let overall = entry.overallProgress
                let params: MediaCreateParams
                let uploadWeight: Double
                switch entry.payload {
                case .unmaterialized(let source):
                    let stageChild = Self.makeSubprogress(
                        of: overall,
                        weight: source.materializationProgressWeight
                    )
                    let materialized = try await materializer.materialize(
                        source: source,
                        into: stageChild
                    )
                    // No checkCancellation here: a cancel that lands now would
                    // cause us to throw and silently discard `materialized`,
                    // leaving its staging directory orphaned. Always hop to
                    // markMaterialized; it owns the post-materialize race.
                    guard let self else {
                        // Actor was deallocated (e.g. registry torn down while
                        // materialize was in flight). markMaterialized won't
                        // run, so remove the staged directory directly.
                        Self.removeStagingDirectory(materialized.stagingDirectory)
                        return
                    }
                    guard await self.markMaterialized(id: id, materialized: materialized) else {
                        // The row was cancelled while materializing;
                        // markMaterialized removed the staged directory.
                        return
                    }
                    try Task.checkCancellation()
                    params = materialized.params
                    uploadWeight = 1.0 - source.materializationProgressWeight
                case .staged(let materialized):
                    // The staged file may be gone (e.g. iOS purged it while
                    // the app was suspended). Surface a clear "file not
                    // found" rather than the opaque transport-level error,
                    // since this path reuses the stored path without
                    // re-materializing.
                    guard FileManager.default.fileExists(atPath: materialized.params.filePath)
                    else {
                        throw MaterializerError.fileNotFound
                    }
                    params = materialized.params
                    uploadWeight = 1.0
                }
                let uploadChild = Self.makeSubprogress(of: overall, weight: uploadWeight)
                _ = try await transport.upload(params: params, fulfilling: uploadChild)
                await self?.markSucceeded(id: id)
            } catch {
                // A user cancel removed the entry synchronously before any
                // error could surface, so markFailed no-ops for it. Any
                // error (cancellation included) arriving while the row is
                // still present was not user-initiated and is shown as a
                // failure instead of silently discarding the upload.
                await self?.markFailed(id: id, error: error)
            }
        }
    }

    /// Records the staged payload for a still-pending row and releases the
    /// original source, so large in-memory payloads (e.g. camera images) are
    /// freed as soon as their bytes are on disk. Returns false when the row
    /// was cancelled while materialization was in flight; cancel() could not
    /// have known about the staged directory (the entry had no materialized
    /// payload yet), so it is removed here.
    private func markMaterialized(id: UUID, materialized: MaterializedUpload) -> Bool {
        guard case .pending(var entry)? = entries[id] else {
            Self.removeStagingDirectory(materialized.stagingDirectory)
            return false
        }
        entry.payload = .staged(materialized)
        entries[id] = .pending(entry)
        return true
    }

    /// Attaches a fresh 0...100 child that claims `weight` of `overall`'s
    /// total, so a stage reports its own fine-grained progress while
    /// contributing its allotted fraction to the row's overall bar.
    private static func makeSubprogress(of overall: Progress, weight: Double) -> Progress {
        let pending = Int64((Double(overall.totalUnitCount) * weight).rounded())
        let child = Progress(totalUnitCount: 100)
        overall.addChild(child, withPendingUnitCount: pending)
        return child
    }

    private func markSucceeded(id: UUID) {
        guard case .pending(let entry)? = entries[id] else { return }
        entries.removeValue(forKey: id)
        Self.removeStagingDirectory(entry.materialized?.stagingDirectory)
    }

    private func markFailed(id: UUID, error: Error) {
        // Failure keeps the entry's slot, only flipping pending to failed.
        guard case .pending(let entry)? = entries[id] else { return }
        var materialized = entry.materialized
        if let staged = materialized, case .fileNotFound? = error as? MaterializerError {
            // The staged file is gone (e.g. purged by the system), so another
            // retry can never succeed. Drop the payload to degrade the row to
            // remove-only and delete any staging directory leftovers.
            Self.removeStagingDirectory(staged.stagingDirectory)
            materialized = nil
        }
        entries[entry.id] = .failed(
            InternalFailed(
                id: entry.id,
                displayName: entry.displayName,
                kind: entry.kind,
                materialized: materialized,
                errorMessage: error.localizedDescription
            )
        )
    }

    /// Cancels the entry's work and defers the staged-file deletion until
    /// the task has fully unwound. The transport opens the staged file
    /// lazily, so deleting it while the task might still open the path would
    /// surface a bogus file-not-found instead of a clean cancellation.
    private func cancelWork(of entry: InternalPending) {
        entry.overallProgress.cancel()
        entry.task.cancel()
        guard let stagingDirectory = entry.materialized?.stagingDirectory else { return }
        let task = entry.task
        Task {
            await task.value
            Self.removeStagingDirectory(stagingDirectory)
        }
    }

    private func makeRetryEntry(from failedEntry: InternalFailed) -> InternalEntry? {
        guard let materialized = failedEntry.materialized else { return nil }
        return .pending(
            InternalPending(
                id: failedEntry.id,
                displayName: failedEntry.displayName,
                kind: failedEntry.kind,
                overallProgress: Progress(totalUnitCount: 100),
                payload: .staged(materialized),
                task: makeWorkTask(for: failedEntry.id)
            )
        )
    }

    private static func removeStagingDirectory(_ url: URL?) {
        guard let url else { return }
        try? FileManager.default.removeItem(at: url)
    }

    private func sourceDisplayName(_ source: UploadSource) -> String {
        switch source {
        case .photoLibrary(_, let name, _): return name ?? Strings.uploadFallbackPhotoName
        case .cameraImage: return Strings.uploadFallbackCameraImageName
        case .cameraVideo: return Strings.uploadFallbackCameraVideoName
        case .file(let url): return url.lastPathComponent
        case .remoteURL(let remote): return remote.suggestedName
        case .imagePlayground(_, let suggestedName): return suggestedName
        }
    }
}

/// Actor-internal upload entry. Holds the rich state (Task handle, staged
/// payload) the view-facing `UploadEntry` omits. The case encodes the
/// pending-vs-failed state directly, so a single `[UUID: InternalEntry]` map
/// keeps that invariant without a second dictionary to synchronize.
private enum InternalEntry {
    case pending(InternalPending)
    case failed(InternalFailed)

    var viewModelValue: UploadEntry {
        switch self {
        case .pending(let p): return .pending(p.viewModelValue)
        case .failed(let f): return .failed(f.viewModelValue)
        }
    }
}

private struct InternalPending {
    /// What the work task still has to do. Holding the source only until
    /// materialization completes releases large in-memory payloads (e.g.
    /// camera images) as soon as their bytes are staged on disk.
    enum Payload {
        case unmaterialized(UploadSource)
        case staged(MaterializedUpload)
    }

    let id: UUID
    let displayName: String
    let kind: MediaKind
    let overallProgress: Progress
    var payload: Payload
    let task: Task<Void, Never>

    var materialized: MaterializedUpload? {
        if case .staged(let materialized) = payload { materialized } else { nil }
    }

    var viewModelValue: PendingUpload {
        PendingUpload(
            id: id,
            displayName: materialized?.displayName ?? displayName,
            kind: materialized?.kind ?? kind,
            progress: overallProgress
        )
    }
}

private struct InternalFailed {
    let id: UUID
    let displayName: String
    let kind: MediaKind
    let materialized: MaterializedUpload?
    let errorMessage: String

    var viewModelValue: FailedUpload {
        FailedUpload(
            id: id,
            displayName: materialized?.displayName ?? displayName,
            kind: materialized?.kind ?? kind,
            errorMessage: errorMessage,
            isRetryable: materialized != nil
        )
    }
}
