@preconcurrency import Combine
import Foundation
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

    private var pending: [UUID: InternalPending] = [:]
    private var failed: [UUID: InternalFailed] = [:]
    /// Single submission-order list shared by pending and failed entries.
    /// In-flight → failed (and failed → pending via Retry) transitions
    /// keep the entry's slot here, so the Uploads screen does not reshuffle
    /// when an upload changes state.
    private var order: [UUID] = []

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
        let entries: [UploadEntry] = order.compactMap { id in
            if let p = pending[id] { return .pending(p.viewModelValue) }
            if let f = failed[id] { return .failed(f.viewModelValue) }
            return nil
        }
        return UploaderState(entries: entries)
    }

    func enqueue(sources: [UploadSource]) {
        for source in sources {
            let id = UUID()
            let overall = Progress(totalUnitCount: 100)
            pending[id] = InternalPending(
                id: id,
                displayName: sourceDisplayName(source),
                kind: sourceKind(source),
                overallProgress: overall,
                materialized: nil,
                task: nil
            )
            order.append(id)
            emit()
            spawnWorkTask(for: id, source: source)
        }
    }

    func cancel(_ uploadID: UUID) {
        guard let entry = pending[uploadID] else { return }
        entry.task?.cancel()
        entry.overallProgress.cancel()
        cleanupTempFile(at: entry.materialized?.tempFileURL)
        pending.removeValue(forKey: uploadID)
        order.removeAll { $0 == uploadID }
        emit()
    }

    func retry(_ uploadID: UUID) {
        guard let failedEntry = failed[uploadID],
            let materialized = failedEntry.materialized
        else {
            return
        }
        // Reuse the failed entry's slot in `order` so the row stays in
        // place across the retry transition.
        failed.removeValue(forKey: uploadID)
        let overall = Progress(totalUnitCount: 100)
        pending[failedEntry.id] = InternalPending(
            id: failedEntry.id,
            displayName: failedEntry.displayName,
            kind: failedEntry.kind,
            overallProgress: overall,
            materialized: materialized,
            task: nil
        )
        emit()
        spawnRetryUploadTask(for: failedEntry.id)
    }

    func dismiss(_ uploadID: UUID) {
        guard let entry = failed.removeValue(forKey: uploadID) else { return }
        order.removeAll { $0 == uploadID }
        cleanupTempFile(at: entry.materialized?.tempFileURL)
        emit()
    }

    func cancelAllPending() {
        for id in order where pending[id] != nil { cancel(id) }
    }

    func retryAllFailed() {
        for id in order where failed[id] != nil { retry(id) }
    }

    func dismissAllFailed() {
        for id in order where failed[id] != nil { dismiss(id) }
    }

    public func tearDown() {
        // Iterate copies — cancel/dismiss mutates `order`.
        for id in order where pending[id] != nil { cancel(id) }
        for id in order where failed[id] != nil { dismiss(id) }
        stateSubject.send(completion: .finished)
    }

    // MARK: - Internals

    private func spawnWorkTask(for id: UUID, source: UploadSource) {
        guard var entry = pending[id] else { return }
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
        pending[id] = entry
    }

    private func markMaterialized(id: UUID, materialized: MaterializedUpload) {
        guard var entry = pending[id] else {
            // cancel() got here first and removed the row; the temp dir
            // we just materialized is now orphaned (cancel() ran before
            // `entry.materialized` was set, so it couldn't have cleaned
            // it up itself). Remove it here.
            cleanupTempFile(at: materialized.tempFileURL)
            return
        }
        entry.materialized = materialized
        pending[id] = entry
        emit()
    }

    /// Retry path: the temp file is already on disk and `params` is set,
    /// so we skip materialization and upload directly into the overall
    /// progress (the upload child gets all 100 pending units).
    private func spawnRetryUploadTask(for id: UUID) {
        guard var entry = pending[id], let params = entry.materialized?.params else { return }
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
        pending[id] = entry
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
        guard let entry = pending.removeValue(forKey: id) else { return }
        order.removeAll { $0 == id }
        cleanupTempFile(at: entry.materialized?.tempFileURL)
        emit()
    }

    private func removePendingIfCancelled(id: UUID) {
        // Either cancel(id) already removed the row (no-op here), or the
        // transport surfaced a cancellation error without an explicit
        // cancel call — in which case the row would leak. Clean up.
        guard let entry = pending.removeValue(forKey: id) else { return }
        entry.overallProgress.cancel()
        cleanupTempFile(at: entry.materialized?.tempFileURL)
        order.removeAll { $0 == id }
        emit()
    }

    private func markFailed(id: UUID, error: Error) {
        // Cancellation is filtered upstream in spawnWorkTask, but be defensive.
        if isCancellationError(error) { return }
        // Failure keeps the slot in `order` — only flips pending → failed.
        guard let entry = pending.removeValue(forKey: id) else { return }
        let f = InternalFailed(
            id: entry.id,
            displayName: entry.displayName,
            kind: entry.kind,
            materialized: entry.materialized,
            errorMessage: (error as? LocalizedError)?.errorDescription
                ?? (error as NSError).localizedDescription
        )
        failed[entry.id] = f
        emit()
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
        }
    }

    private func sourceKind(_ source: UploadSource) -> MediaKind {
        switch source {
        case .photoLibrary(_, _, let hint):
            if hint.conforms(to: .image) { return .image }
            if hint.conforms(to: .movie) { return .video }
            if hint.conforms(to: .audio) { return .audio }
            return .document
        case .cameraImage: return .image
        case .cameraVideo: return .video
        case .file(let url):
            if let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType {
                if type.conforms(to: .image) { return .image }
                if type.conforms(to: .movie) { return .video }
                if type.conforms(to: .audio) { return .audio }
            }
            return .document
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
