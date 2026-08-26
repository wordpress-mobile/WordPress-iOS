import AVFoundation
import Foundation
import Testing
import UniformTypeIdentifiers
import WordPressAPI
import WordPressAPIInternal
@testable import WordPressMediaLibrary

// MARK: - Fake upload transports

actor FakeUploadTransport: MediaUploadTransport {
    var uploadCount = 0
    var responses: [Result<MediaWithEditContext, Error>] = []

    func upload(
        params: MediaCreateParams,
        fulfilling progress: Progress
    ) async throws -> MediaWithEditContext {
        uploadCount += 1
        progress.completedUnitCount = progress.totalUnitCount
        if responses.isEmpty {
            return MediaWithEditContext.fixture()
        }
        return try responses.removeFirst().get()
    }

    func setResponses(_ responses: [Result<MediaWithEditContext, Error>]) {
        self.responses = responses
    }
}

/// A transport that blocks until signalled, used to test cancel mid-flight.
/// Optionally fails the first call instead, to build a mixed (1 failed +
/// 1 pending) state through a single uploader.
actor BlockingFakeUploadTransport: MediaUploadTransport {
    private var callIndex = 0
    private var firstCallError: Error?
    private var continuation: CheckedContinuation<Void, Never>?

    func failFirstCall(with error: Error) {
        firstCallError = error
    }

    func upload(
        params: MediaCreateParams,
        fulfilling progress: Progress
    ) async throws -> MediaWithEditContext {
        callIndex += 1
        if callIndex == 1, let firstCallError {
            throw firstCallError
        }
        await withCheckedContinuation { cont in
            self.continuation = cont
        }
        try Task.checkCancellation()
        return MediaWithEditContext.fixture()
    }

    /// Returns once an upload call is suspended on the continuation.
    func waitUntilBlocked() async {
        while continuation == nil {
            await Task.yield()
        }
    }

    func unblock() {
        continuation?.resume()
        continuation = nil
    }
}

// MARK: - Waiting on uploader state

struct WaitTimedOut: Error {}

/// Returns the first uploader state (starting with the current one) that
/// satisfies `predicate`, or throws once `timeout` elapses or the publisher
/// finishes.
@discardableResult
func waitForState(
    of uploader: MediaUploader,
    timeout: Duration = .seconds(5),
    where predicate: @escaping @Sendable (UploaderState) -> Bool
) async throws -> UploaderState {
    try await withThrowingTaskGroup(of: UploaderState.self) { group in
        group.addTask {
            for await state in uploader.statePublisher.values where predicate(state) {
                return state
            }
            throw WaitTimedOut()
        }
        group.addTask {
            try await Task.sleep(for: timeout)
            throw WaitTimedOut()
        }
        defer { group.cancelAll() }
        return try await group.next()!
    }
}

/// Polls `condition` until it holds, for side effects (like file deletion)
/// that no published state reflects.
func waitUntil(
    timeout: Duration = .seconds(5),
    _ condition: () -> Bool
) async throws {
    let clock = ContinuousClock()
    let deadline = clock.now + timeout
    while !condition() {
        guard clock.now < deadline else { throw WaitTimedOut() }
        try await Task.sleep(for: .milliseconds(10))
    }
}

// MARK: - MediaWithEditContext fixture

extension MediaWithEditContext {
    static func fixture(id: Int64 = 9999) -> MediaWithEditContext {
        MediaWithEditContext(
            id: id,
            date: "",
            dateGmt: Date(timeIntervalSince1970: 0),
            guid: PostGuidWithEditContext(raw: nil, rendered: ""),
            link: "",
            modified: "",
            modifiedGmt: Date(timeIntervalSince1970: 0),
            slug: "",
            status: .inherit,
            postType: "",
            password: nil,
            permalinkTemplate: "",
            generatedSlug: "",
            title: PostTitleWithEditContext(raw: nil, rendered: ""),
            author: 0,
            commentStatus: .closed,
            pingStatus: .closed,
            template: "",
            altText: "",
            caption: MediaCaptionWithEditContext(raw: "", rendered: ""),
            description: MediaDescriptionWithEditContext(raw: "", rendered: ""),
            mediaType: .file,
            mimeType: "",
            mediaDetails: MediaDetails(noHandle: .init()),
            postId: nil,
            sourceUrl: "",
            missingImageSizes: []
        )
    }
}

// MARK: - MediaUploadPolicy helper

func makeAllowEverythingPolicy() -> MediaUploadPolicy {
    makePolicy(isAllowedForUpload: { _, _ in true })
}

/// A policy that rejects every file, used to force materialization failures.
func makeRejectEverythingPolicy() -> MediaUploadPolicy {
    makePolicy(isAllowedForUpload: { _, _ in false })
}

func makePolicy(
    isAllowedForUpload: @escaping @Sendable (UTType, String) -> Bool = { _, _ in true },
    filePickerContentTypes: [UTType] = [.content],
    imageMaxDimension: Int? = nil,
    videoMaxDurationSeconds: TimeInterval? = nil,
    stripGPSLocation: Bool = false
) -> MediaUploadPolicy {
    MediaUploadPolicy(
        filePickerContentTypes: filePickerContentTypes,
        isAllowedForUpload: isAllowedForUpload,
        imageMaxDimension: imageMaxDimension,
        imageJpegQuality: 0.9,
        convertHEICToJPEG: true,
        videoMaxDurationSeconds: videoMaxDurationSeconds,
        videoExportPreset: AVAssetExportPresetMediumQuality,
        videoOutputContentType: .mpeg4Movie,
        stripGPSLocation: stripGPSLocation
    )
}

// MARK: - Mock materializer

/// Test seam that lets a test drive materialization timing and outcome.
/// - Suspends on a "start" continuation when `materialize` is called.
/// - When unblocked by the test, either throws the configured error or
///   returns the configured `MaterializedUpload`.
actor MockMaterializer: MediaSourceMaterializing {
    enum Outcome {
        case success(MaterializedUpload)
        case failure(Error)
    }

    private var startedContinuations: [CheckedContinuation<Void, Never>] = []
    private var completionContinuations: [CheckedContinuation<Outcome, Never>] = []
    private(set) var lastStageProgress: Progress?

    func materialize(
        source: UploadSource,
        into stageProgress: Progress
    ) async throws -> MaterializedUpload {
        lastStageProgress = stageProgress
        await withCheckedContinuation { cont in
            startedContinuations.append(cont)
        }
        let outcome = await withCheckedContinuation { cont in
            completionContinuations.append(cont)
        }
        // Mirror the real materializer's contract: if cancellation is
        // observed before we hand back the payload, clean up the temp dir
        // so the caller is not responsible for it.
        if Task.isCancelled {
            if case .success(let m) = outcome {
                try? FileManager.default.removeItem(at: m.stagingDirectory)
            }
            throw CancellationError()
        }
        switch outcome {
        case .success(let m): return m
        case .failure(let e): throw e
        }
    }

    /// Signals that `materialize` has been entered. The test typically
    /// awaits this before driving stageProgress or calling cancel.
    func waitForStart() async {
        // Spin until at least one start continuation has been captured.
        while startedContinuations.isEmpty {
            await Task.yield()
        }
        let cont = startedContinuations.removeFirst()
        cont.resume()
    }

    /// Resolve the in-flight `materialize` call. If the work Task hasn't
    /// reached the completion suspension point yet, spin-wait briefly so
    /// callers don't need to insert sleeps.
    func complete(with outcome: Outcome) async {
        while completionContinuations.isEmpty {
            await Task.yield()
        }
        let cont = completionContinuations.removeFirst()
        cont.resume(returning: outcome)
    }
}

// MARK: - Temp file helpers

/// Per-suite root for fixture files, removed when the suite deinitializes so
/// tests need no per-file cleanup.
final class TempFixtureDirectory {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("MediaLibraryTests-\(UUID().uuidString)", isDirectory: true)

    deinit {
        try? FileManager.default.removeItem(at: root)
    }

    /// Creates a fresh, empty directory under the root.
    func makeDirectory() throws -> URL {
        let dir = root.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Writes `content` into a fresh directory under the root.
    func writeFile(name: String, content: Data) throws -> URL {
        let url = try makeDirectory().appendingPathComponent(name)
        try content.write(to: url)
        return url
    }

    func writePDF(name: String = "doc.pdf") throws -> URL {
        try writeFile(name: name, content: Data("%PDF-1.4\n%EOF\n".utf8))
    }
}
