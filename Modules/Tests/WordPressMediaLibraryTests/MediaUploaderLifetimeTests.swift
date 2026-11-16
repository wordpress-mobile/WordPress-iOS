import Foundation
import Testing
import UIKit
import WordPressAPI
@testable import WordPressMediaLibrary

@Suite("Uploader source lifetime")
final class MediaUploaderLifetimeTests {
    private let fixtures = TempFixtureDirectory()

    @Test("camera image is released after staging while upload is blocked", arguments: 1...3)
    func releasesCameraImageBeforeUploadCompletes(iteration: Int) async throws {
        let transport = BlockingFakeUploadTransport()
        let uploader = MediaUploader(
            transport: transport,
            materializer: ImmediateMaterializer(root: try fixtures.makeDirectory())
        )
        let box = WeakImageBox()
        await Self.enqueueCameraImage(on: uploader, box: box)
        await transport.waitUntilBlocked()
        #expect(!box.isAlive, "The staged upload must not keep the decoded source image alive")
        await transport.unblock()
        try await waitForState(of: uploader) { $0.isEmpty }
        await uploader.tearDown()
    }

    @Test(
        "retained preparation source is released after recovery or removal",
        arguments: [
            "retry", "remove", "removeAll", "tearDown"
        ]
    )
    func releasesFailedPreparationSource(action: String) async throws {
        let uploader = MediaUploader(
            transport: FakeUploadTransport(),
            materializer: RetryTestMaterializer(root: try fixtures.makeDirectory(), firstError: URLError(.timedOut))
        )
        let box = WeakImageBox()
        await Self.enqueueCameraImage(on: uploader, box: box)
        let state = try await waitForState(of: uploader) { $0.failed.count == 1 }
        #expect(state.failed[0].isRetryable)
        #expect(box.isAlive)
        switch action {
        case "retry": await uploader.retry(state.failed[0].id)
        case "remove": await uploader.remove(state.failed[0].id)
        case "removeAll": await uploader.removeAllFailed()
        default: await uploader.tearDown()
        }
        try await waitForUploadCondition { await uploader.snapshot().isEmpty }
        try await waitUntil { !box.isAlive }
        await uploader.tearDown()
    }

    @MainActor
    private static func enqueueCameraImage(on uploader: MediaUploader, box: WeakImageBox) async {
        let image = autoreleasepool {
            UIGraphicsImageRenderer(size: CGSize(width: 64, height: 64))
                .image { context in
                    UIColor.red.setFill()
                    context.fill(CGRect(x: 0, y: 0, width: 64, height: 64))
                }
        }
        box.store(image)
        await uploader.enqueue(sources: [.cameraImage(image, capturedAt: Date())])
    }
}

private final class WeakImageBox: @unchecked Sendable {
    private let lock = NSLock()
    private weak var image: UIImage?

    func store(_ image: UIImage) { lock.withLock { self.image = image } }
    var isAlive: Bool { lock.withLock { image != nil } }
}

private struct ImmediateMaterializer: MediaSourceMaterializing {
    let root: URL

    func materialize(source: UploadSource, into stageProgress: Progress) async throws -> MaterializedUpload {
        let directory = root.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("staged.bin")
        try Data([1, 2, 3]).write(to: file)
        return MaterializedUpload(tempFileURL: file, params: .init(filePath: file.path), kind: .image)
    }
}
