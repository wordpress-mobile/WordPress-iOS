import Foundation
import Testing
import UniformTypeIdentifiers
import WordPressAPI
import WordPressAPIInternal
@testable import WordPressMediaLibrary

// MARK: - Recording tracker

@MainActor
final class RecordingMediaTracker: MediaTracker {
    var events: [MediaTrackerEvent] = []
    func track(_ event: MediaTrackerEvent) { events.append(event) }
}

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
actor BlockingFakeUploadTransport: MediaUploadTransport {
    private var continuation: CheckedContinuation<Void, Never>?

    func upload(
        params: MediaCreateParams,
        fulfilling progress: Progress
    ) async throws -> MediaWithEditContext {
        await withCheckedContinuation { cont in
            self.continuation = cont
        }
        try Task.checkCancellation()
        return MediaWithEditContext.fixture()
    }

    func unblock() {
        continuation?.resume()
        continuation = nil
    }
}

/// Fails the first call then blocks the second — used to build a mixed
/// (1 failed + 1 pending) banner state through a single uploader.
actor BlockingAndThenFailFakeUploadTransport: MediaUploadTransport {
    private var callIndex = 0
    private var firstCallError: Error?
    private var continuation: CheckedContinuation<Void, Never>?

    func configureFirstCallAsFailure(_ error: Error) {
        self.firstCallError = error
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

    func unblock() {
        continuation?.resume()
        continuation = nil
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
    MediaUploadPolicy(
        filePickerContentTypes: [.content],
        isAllowedForUpload: { _, _ in true },
        imageMaxDimension: nil,
        imageJpegQuality: 0.9,
        convertHEICToJPEG: true,
        videoMaxDurationSeconds: nil,
        videoExportPreset: "AVAssetExportPresetMediumQuality",
        videoOutputContentType: .mpeg4Movie,
        stripImageLocation: false
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
    private(set) var sawCancellation = false

    nonisolated func materialize(
        source: UploadSource,
        into stageProgress: Progress
    ) async throws -> MaterializedUpload {
        try await materializeAsync(source: source, into: stageProgress)
    }

    private func materializeAsync(
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
                try? FileManager.default.removeItem(at: m.tempFileURL.deletingLastPathComponent())
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

func writeTempFile(name: String, content: Data) throws -> URL {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("MediaLibraryTests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let url = dir.appendingPathComponent(name)
    try content.write(to: url)
    return url
}

func writeTempPDF(name: String = "doc.pdf") throws -> URL {
    try writeTempFile(name: name, content: Data("%PDF-1.4\n%EOF\n".utf8))
}

func writeTempJPEG(name: String = "IMG_1234.jpg") throws -> URL {
    let jpegHeader: [UInt8] = [0xFF, 0xD8, 0xFF, 0xE0]
    return try writeTempFile(name: name, content: Data(jpegHeader))
}

func writeTempMOV(name: String = "IMG_1234.mov") throws -> URL {
    try writeTempFile(name: name, content: Data("fake-mov".utf8))
}
