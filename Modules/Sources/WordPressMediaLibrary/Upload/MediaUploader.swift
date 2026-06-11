@preconcurrency import Combine
import Foundation
import OrderedCollections
import UniformTypeIdentifiers
import WordPressAPI
import WordPressCore

public actor MediaUploader {
    nonisolated let filePickerContentTypes: [UTType]

    private let transport: any MediaUploadTransport
    private let materializer: any MediaSourceMaterializing

    /// Multicasts state to every observer and replays the latest snapshot
    /// to new subscribers, so a re-pushed Media Library screen sees the
    /// in-flight state immediately.
    private nonisolated let stateSubject = CurrentValueSubject<UploaderState, Never>(
        UploaderState(entries: [])
    )

    /// Every in-flight or failed upload, keyed by id and held in submission
    /// order. The `InternalEntry` case encodes pending-vs-failed, so an id is
    /// in exactly one state and can never be orphaned. In-flight → failed (and
    /// failed → pending via Retry) updates the value in place, preserving its
    /// slot so the Uploads screen does not reshuffle. `didSet` is the single
    /// emit point: every mutation publishes a fresh snapshot.
    private var entries: OrderedDictionary<UUID, InternalEntry> = [:] {
        didSet { emit() }
    }

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
        self.filePickerContentTypes = policy.filePickerContentTypes
    }

    /// Module-internal test seam.
    init(
        transport: any MediaUploadTransport,
        materializer: any MediaSourceMaterializing,
        filePickerContentTypes: [UTType]
    ) {
        self.transport = transport
        self.materializer = materializer
        self.filePickerContentTypes = filePickerContentTypes
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

    func enqueue(sources: [UploadSource]) {
        for source in sources {
            let id = UUID()
            let overall = Progress(totalUnitCount: 100)
            entries[id] = .pending(
                InternalPending(
                    id: id,
                    displayName: sourceDisplayName(source),
                    kind: source.estimatedKind,
                    overallProgress: overall,
                    materialized: nil,
                    task: nil
                )
            )
            spawnWorkTask(for: id, source: source)
        }
    }

    func cancel(_ uploadID: UUID) {
        guard case .pending(let entry)? = entries[uploadID] else { return }
        entry.task?.cancel()
        entry.overallProgress.cancel()
        cleanupTempFile(at: entry.materialized?.tempFileURL)
        entries.removeValue(forKey: uploadID)
    }

    func retry(_ uploadID: UUID) {
        guard case .failed(let failedEntry)? = entries[uploadID],
            let materialized = failedEntry.materialized
        else {
            return
        }
        // Overwrite the entry in place so it keeps its slot in `order`
        // across the failed → pending retry transition.
        let overall = Progress(totalUnitCount: 100)
        entries[failedEntry.id] = .pending(
            InternalPending(
                id: failedEntry.id,
                displayName: failedEntry.displayName,
                kind: failedEntry.kind,
                overallProgress: overall,
                materialized: materialized,
                task: nil
            )
        )
        spawnRetryUploadTask(for: failedEntry.id)
    }

    func dismiss(_ uploadID: UUID) {
        guard case .failed(let entry)? = entries[uploadID] else { return }
        entries.removeValue(forKey: uploadID)
        cleanupTempFile(at: entry.materialized?.tempFileURL)
    }

    func cancelAllPending() {
        for id in Array(entries.keys) where entries[id]?.isPending == true { cancel(id) }
    }

    func retryAllFailed() {
        for id in Array(entries.keys) where entries[id]?.isFailed == true { retry(id) }
    }

    func dismissAllFailed() {
        for id in Array(entries.keys) where entries[id]?.isFailed == true { dismiss(id) }
    }

    public func tearDown() {
        // Iterate copies — cancel/dismiss mutates `entries`.
        for id in Array(entries.keys) where entries[id]?.isPending == true { cancel(id) }
        for id in Array(entries.keys) where entries[id]?.isFailed == true { dismiss(id) }
        stateSubject.send(completion: .finished)
    }

    // MARK: - Internals

    private func spawnWorkTask(for id: UUID, source: UploadSource) {
        guard case .pending(var entry)? = entries[id] else { return }
        let overall = entry.overallProgress
        let task = Task<Void, Never> { [weak self, materializer, transport] in
            do {
                let materialized = try await Self.runMaterializeStage(
                    source: source,
                    materializer: materializer,
                    overall: overall
                )
                // No checkCancellation here: a cancel that lands now would
                // cause us to throw and silently discard `materialized`,
                // leaving its temp dir orphaned. Always hop to
                // markMaterialized; it owns the post-materialize race.
                guard let strongSelf = self else {
                    // Actor was deallocated (e.g. registry torn down while
                    // materialize was in flight). markMaterialized won't run,
                    // so clean up the materialized temp dir directly.
                    try? FileManager.default.removeItem(
                        at: materialized.tempFileURL.deletingLastPathComponent()
                    )
                    return
                }
                await strongSelf.markMaterialized(id: id, materialized: materialized)
                try Task.checkCancellation()

                try await Self.runUploadStage(
                    params: materialized.params,
                    transport: transport,
                    overall: overall,
                    progressWeight: 1.0 - source.materializationProgressWeight
                )
                await strongSelf.markSucceeded(id: id)
            } catch {
                if isCancellationError(error) {
                    await self?.removePendingIfCancelled(id: id)
                    return
                }
                await self?.markFailed(id: id, error: error)
            }
        }
        entry.task = task
        entries[id] = .pending(entry)
    }

    private func markMaterialized(id: UUID, materialized: MaterializedUpload) {
        guard case .pending(var entry)? = entries[id] else {
            // cancel() got here first and removed the row; the temp dir
            // we just materialized is now orphaned (cancel() ran before
            // `entry.materialized` was set, so it couldn't have cleaned
            // it up itself). Remove it here.
            cleanupTempFile(at: materialized.tempFileURL)
            return
        }
        entry.materialized = materialized
        entries[id] = .pending(entry)
    }

    /// Retry path: the temp file is already on disk and `params` is set,
    /// so we skip materialization and upload directly into the overall
    /// progress (the upload child gets all 100 pending units).
    private func spawnRetryUploadTask(for id: UUID) {
        guard case .pending(var entry)? = entries[id], let params = entry.materialized?.params
        else { return }
        let overall = entry.overallProgress
        let task = Task<Void, Never> { [weak self, transport] in
            do {
                try await Self.runUploadStage(
                    params: params,
                    transport: transport,
                    overall: overall,
                    progressWeight: 1.0
                )
                await self?.markSucceeded(id: id)
            } catch {
                if isCancellationError(error) {
                    await self?.removePendingIfCancelled(id: id)
                    return
                }
                await self?.markFailed(id: id, error: error)
            }
        }
        entry.task = task
        entries[id] = .pending(entry)
    }

    private static func runMaterializeStage(
        source: UploadSource,
        materializer: any MediaSourceMaterializing,
        overall: Progress
    ) async throws -> MaterializedUpload {
        let weight = source.materializationProgressWeight
        let stagePending = Int64(
            (Double(overall.totalUnitCount) * weight).rounded()
        )
        let stageChild = Progress(totalUnitCount: 100)
        overall.addChild(stageChild, withPendingUnitCount: stagePending)
        return try await materializer.materialize(
            source: source,
            into: stageChild
        )
    }

    private static func runUploadStage(
        params: MediaCreateParams,
        transport: any MediaUploadTransport,
        overall: Progress,
        progressWeight: Double
    ) async throws {
        let uploadPending = Int64(
            (Double(overall.totalUnitCount) * progressWeight).rounded()
        )
        let uploadChild = Progress(totalUnitCount: 100)
        overall.addChild(uploadChild, withPendingUnitCount: uploadPending)
        _ = try await transport.upload(params: params, fulfilling: uploadChild)
    }

    private func markSucceeded(id: UUID) {
        guard case .pending(let entry)? = entries[id] else { return }
        entries.removeValue(forKey: id)
        cleanupTempFile(at: entry.materialized?.tempFileURL)
    }

    private func removePendingIfCancelled(id: UUID) {
        // Either cancel(id) already removed the row (no-op here), or the
        // transport surfaced a cancellation error without an explicit
        // cancel call — in which case the row would leak. Clean up.
        guard case .pending(let entry)? = entries[id] else { return }
        entries.removeValue(forKey: id)
        entry.overallProgress.cancel()
        cleanupTempFile(at: entry.materialized?.tempFileURL)
    }

    private func markFailed(id: UUID, error: Error) {
        // Cancellation is filtered upstream in spawnWorkTask, but be defensive.
        if isCancellationError(error) { return }
        // Failure keeps the slot in `order` — only flips pending → failed.
        guard case .pending(let entry)? = entries[id] else { return }
        let failedEntry = InternalFailed(
            id: entry.id,
            displayName: entry.displayName,
            kind: entry.kind,
            materialized: entry.materialized,
            errorMessage: (error as? LocalizedError)?.errorDescription
                ?? (error as NSError).localizedDescription
        )
        entries[entry.id] = .failed(failedEntry)
    }

    private func emit() {
        stateSubject.send(snapshot())
    }

    private func cleanupTempFile(at url: URL?) {
        guard let url else { return }
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
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

/// Module-local mirror of the app target's `Error.isCancellationError`
/// extension. We duplicate rather than promote to a shared module because
/// `WordPressMediaLibrary` already imports `WordPressAPI` (which owns
/// `WpApiError`); no extra dependency is needed.
private func isCancellationError(_ error: Error) -> Bool {
    if error is CancellationError { return true }
    if let urlErr = error as? URLError, urlErr.code == .cancelled { return true }
    if let apiErr = error as? WpApiError, apiErr.isCancellationError { return true }
    return false
}

/// Actor-internal upload entry. Holds the rich state (Task handle, owned
/// temp-file URL) the view-facing `UploadEntry` omits. The case encodes the
/// pending-vs-failed state directly, so a single `[UUID: InternalEntry]` map
/// keeps that invariant without a second dictionary to synchronize.
private enum InternalEntry {
    case pending(InternalPending)
    case failed(InternalFailed)

    var isPending: Bool {
        if case .pending = self { return true }
        return false
    }

    var isFailed: Bool {
        if case .failed = self { return true }
        return false
    }

    var viewModelValue: UploadEntry {
        switch self {
        case .pending(let p): return .pending(p.viewModelValue)
        case .failed(let f): return .failed(f.viewModelValue)
        }
    }
}

private struct InternalPending {
    let id: UUID
    let displayName: String
    let kind: MediaKind
    let overallProgress: Progress
    var materialized: MaterializedUpload?
    var task: Task<Void, Never>?

    var viewModelValue: PendingUpload {
        PendingUpload(
            id: id,
            displayName: materialized?.displayName ?? displayName,
            kind: materialized?.kind ?? kind,
            progress: overallProgress,
            localFileURL: materialized?.tempFileURL
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
            isRetryable: materialized != nil,
            localFileURL: materialized?.tempFileURL
        )
    }
}
