import Foundation
import Testing
import UniformTypeIdentifiers
import WordPressAPI
@testable import WordPressMediaLibrary

@Suite("Uploader preparation retry")
final class MediaUploaderPreparationRetryTests {
    private let fixtures = TempFixtureDirectory()

    @Test("single and bulk retry repeat preparation with the original materializer", arguments: [false, true])
    func retriesTransientPreparationFailure(bulk: Bool) async throws {
        let materializer = RetryTestMaterializer(
            root: try fixtures.makeDirectory(),
            firstError: MaterializerError.remoteDownloadFailed(underlyingError: URLError(.timedOut))
        )
        let transport = FakeUploadTransport()
        let uploader = MediaUploader(transport: transport, materializer: materializer)
        await uploader.enqueue(sources: [remoteSource])
        let state = try await waitForState(of: uploader) { $0.failed.count == 1 }
        let failed = try #require(state.failed.first)
        #expect(failed.isRetryable)
        #expect(await transport.uploadCount == 0)
        await uploader.updatePolicy(makeRejectEverythingPolicy())
        if bulk {
            await uploader.retryAllFailed()
        } else {
            await uploader.retry(failed.id)
        }
        try await waitForState(of: uploader) { $0.isEmpty }
        #expect(await materializer.calls == 2)
        #expect(await transport.uploadCount == 1)
        await uploader.tearDown()
    }

    @Test("preparation retry waits behind active work")
    func preparationRetryUsesAdmissionLimit() async throws {
        let materializer = RetryTestMaterializer(root: try fixtures.makeDirectory(), firstError: URLError(.timedOut))
        let transport = BlockingFakeUploadTransport()
        let uploader = MediaUploader(transport: transport, materializer: materializer, maxConcurrentUploads: 1)
        await uploader.enqueue(sources: [remoteSource])
        let failed = try await waitForState(of: uploader) { $0.failed.count == 1 }
        await uploader.enqueue(sources: [.file(try fixtures.writePDF())])
        await transport.waitUntilBlocked()
        await uploader.retry(failed.failed[0].id)
        let queued = await uploader.snapshot()
        #expect(queued.pending.first?.id == failed.failed[0].id)
        #expect(queued.pending.count == 2)
        #expect(await materializer.calls == 2)
        #expect(await transport.blockedCount == 1)
        await transport.unblock()
        try await waitForState(of: uploader) { $0.isEmpty }
        #expect(await materializer.calls == 3)
        await uploader.tearDown()
    }

    @Test(
        "policy, content and unrecognized failures stay remove-only",
        arguments: [
            MaterializerError.disallowedContentType,
            .invalidImageData,
            .fileNotFound,
            .remoteDownloadFailed(underlyingError: URLError(.badURL)),
            .videoExportFailed(underlyingError: NSError(domain: "AVFoundation", code: -1))
        ]
    )
    func permanentPreparationFailureIsNotRetryable(error: MaterializerError) async throws {
        let materializer = RetryTestMaterializer(root: try fixtures.makeDirectory(), firstError: error)
        let uploader = MediaUploader(transport: FakeUploadTransport(), materializer: materializer)
        await uploader.enqueue(sources: [remoteSource])
        let state = try await waitForState(of: uploader) { $0.failed.count == 1 }
        #expect(!state.failed[0].isRetryable)
        await uploader.retry(state.failed[0].id)
        await uploader.retryAllFailed()
        #expect(await materializer.calls == 1)
        #expect(await uploader.snapshot().failed.count == 1)
        await uploader.removeAllFailed()
    }

    @Test(
        "recognized URL loading errors remain retryable through a Photos provider wrapper",
        arguments: [
            URLError.timedOut, .networkConnectionLost, .notConnectedToInternet,
            .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed
        ]
    )
    func recognizesWrappedNetworkFailure(code: URLError.Code) {
        let providerError = NSError(
            domain: NSItemProviderErrorDomain,
            code: -1,
            userInfo: [NSUnderlyingErrorKey: URLError(code)]
        )
        #expect(MaterializerError.isTransientPreparationFailure(providerError))
        #expect(!MaterializerError.isTransientPreparationFailure(URLError(.cancelled)))
    }

    private var remoteSource: UploadSource {
        .remoteURL(
            .init(
                url: URL(string: "https://example.com/photo.jpg")!,
                suggestedName: "photo.jpg",
                contentType: .jpeg,
                caption: nil
            )
        )
    }
}

actor RetryTestMaterializer: MediaSourceMaterializing {
    private let root: URL
    private var firstError: Error?
    private(set) var calls = 0

    init(root: URL, firstError: Error) {
        self.root = root
        self.firstError = firstError
    }

    func materialize(source: UploadSource, into stageProgress: Progress) async throws -> MaterializedUpload {
        calls += 1
        if let error = firstError {
            firstError = nil
            throw error
        }
        let directory = root.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("prepared.bin")
        try Data([1]).write(to: file)
        return MaterializedUpload(tempFileURL: file, params: .init(filePath: file.path), kind: .image)
    }
}
