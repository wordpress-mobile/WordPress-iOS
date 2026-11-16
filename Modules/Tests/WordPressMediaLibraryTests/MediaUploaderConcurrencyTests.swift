import Foundation
import Testing
import WordPressAPI
import WordPressAPIInternal
@testable import WordPressMediaLibrary

@Suite("Uploader admission")
final class MediaUploaderConcurrencyTests {
    private let fixtures = TempFixtureDirectory()

    @Test("forty queued sources share three complete pipelines")
    func defaultLimitBoundsPreparationAndUploadTogether() async throws {
        let preparationGate = BlockingFakeUploadTransport()
        let uploadGate = BlockingFakeUploadTransport()
        let activity = UploadActivity()
        let materializer = GatedMaterializer(
            root: try fixtures.makeDirectory(),
            gate: preparationGate,
            activity: activity
        )
        let uploader = MediaUploader(
            transport: ActivityTransport(gate: uploadGate, activity: activity),
            materializer: materializer
        )
        let sources = try (0..<40).map { try fixtures.writePDF(name: "item-\($0).pdf") }
        await uploader.enqueue(sources: sources.map(UploadSource.file))
        await preparationGate.waitUntilBlocked(count: 3)
        let queued = await uploader.snapshot()
        #expect(queued.pending.map(\.displayName) == sources.map(\.lastPathComponent))
        #expect(await activity.started == 3)
        await preparationGate.unblock()
        await uploadGate.waitUntilBlocked(count: 3)
        #expect(await activity.started == 3, "Upload waiters must keep their preparation slots")
        await uploadGate.unblock()
        try await waitForState(of: uploader) { $0.isEmpty }
        #expect(await activity.started == 40)
        #expect(await activity.peak == 3)
        #expect(await activity.activeCount == 0)
        await uploader.tearDown()
    }

    @Test("cancelling a waiting row never materializes it")
    func cancelsWaitingJob() async throws {
        let gate = BlockingFakeUploadTransport()
        let uploader = fixtures.makeUploader(
            transport: gate,
            policy: makeAllowEverythingPolicy(),
            maxConcurrentUploads: 1
        )
        let first = try fixtures.writePDF(name: "first.pdf")
        let waiting = try fixtures.writePDF(name: "waiting.pdf")
        await uploader.enqueue(sources: [.file(first), .file(waiting)])
        await gate.waitUntilBlocked()
        let state = await uploader.snapshot()
        await uploader.cancel(state.pending[1].id)
        #expect(await uploader.snapshot().pending.map(\.displayName) == ["first.pdf"])
        await gate.unblock()
        try await waitForState(of: uploader) { $0.isEmpty }
        let staged = try FileManager.default.subpathsOfDirectory(atPath: fixtures.root.path)
        #expect(staged.filter { $0.hasSuffix("waiting.pdf") }.count == 1, "Only the source fixture should exist")
        await uploader.tearDown()
    }

    @Test("retry waits for an occupied slot and keeps its row position")
    func retryUsesAdmissionLimit() async throws {
        let gate = BlockingFakeUploadTransport()
        await gate.failFirstCall(with: URLError(.timedOut))
        let uploader = fixtures.makeUploader(
            transport: gate,
            policy: makeAllowEverythingPolicy(),
            maxConcurrentUploads: 1
        )
        let first = try fixtures.writePDF(name: "failed.pdf")
        await uploader.enqueue(sources: [.file(first)])
        let failed = try await waitForState(of: uploader) { $0.failed.count == 1 }
        let second = try fixtures.writePDF(name: "active.pdf")
        await uploader.enqueue(sources: [.file(second)])
        await gate.waitUntilBlocked()
        await uploader.retry(failed.failed[0].id)
        let state = await uploader.snapshot()
        #expect(state.pending.map(\.displayName) == ["failed.pdf", "active.pdf"])
        #expect(await gate.blockedCount == 1)
        await gate.unblock()
        try await waitForState(of: uploader) { $0.isEmpty }
        await uploader.tearDown()
    }

    @Test("teardown cancels active work and never starts the waiting batch")
    func teardownDrainsQueuedJobs() async throws {
        let gate = BlockingFakeUploadTransport()
        let activity = UploadActivity()
        let uploader = MediaUploader(
            transport: FakeUploadTransport(),
            materializer: GatedMaterializer(root: try fixtures.makeDirectory(), gate: gate, activity: activity),
            maxConcurrentUploads: 1
        )
        let source = try fixtures.writePDF()
        await uploader.enqueue(sources: Array(repeating: .file(source), count: 10))
        await gate.waitUntilBlocked()
        await uploader.tearDown()
        try await waitForUploadCondition { await activity.activeCount == 0 }
        #expect(await activity.started == 1)
        #expect(await uploader.snapshot().isEmpty)
        await uploader.enqueue(sources: [.file(source)])
        #expect(await activity.started == 1)
    }
}

private actor UploadActivity {
    private var active: Set<String> = []
    private(set) var started = 0
    private(set) var peak = 0
    var activeCount: Int { active.count }

    func begin(_ id: String) {
        active.insert(id)
        started += 1
        peak = max(peak, active.count)
    }

    func end(_ id: String) { active.remove(id) }
}

private struct GatedMaterializer: MediaSourceMaterializing {
    let root: URL
    let gate: BlockingFakeUploadTransport
    let activity: UploadActivity

    func materialize(source: UploadSource, into stageProgress: Progress) async throws -> MaterializedUpload {
        let directory = root.appendingPathComponent(UUID().uuidString)
        await activity.begin(directory.path)
        do {
            _ = try await gate.upload(params: .init(filePath: directory.path), fulfilling: stageProgress)
            try Task.checkCancellation()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let file = directory.appendingPathComponent("staged.bin")
            try Data([1]).write(to: file)
            return MaterializedUpload(tempFileURL: file, params: .init(filePath: file.path), kind: .document)
        } catch {
            await activity.end(directory.path)
            try? FileManager.default.removeItem(at: directory)
            throw error
        }
    }
}

private struct ActivityTransport: MediaUploadTransport {
    let gate: BlockingFakeUploadTransport
    let activity: UploadActivity

    func upload(params: MediaCreateParams, fulfilling progress: Progress) async throws -> MediaWithEditContext {
        let id = URL(fileURLWithPath: params.filePath).deletingLastPathComponent().path
        do {
            let result = try await gate.upload(params: params, fulfilling: progress)
            await activity.end(id)
            return result
        } catch {
            await activity.end(id)
            throw error
        }
    }
}

func waitForUploadCondition(_ condition: () async -> Bool) async throws {
    let clock = ContinuousClock()
    let deadline = clock.now + .seconds(5)
    while !(await condition()) {
        guard clock.now < deadline else { throw WaitTimedOut() }
        try await Task.sleep(for: .milliseconds(10))
    }
}
