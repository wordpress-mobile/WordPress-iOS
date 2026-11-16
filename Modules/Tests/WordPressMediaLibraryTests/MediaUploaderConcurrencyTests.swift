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
        try await preparationGate.waitUntilBlocked(count: 3)
        let queued = await uploader.snapshot()
        #expect(queued.pending.map(\.displayName) == sources.map(\.lastPathComponent))
        #expect(await activity.started == 3)
        await preparationGate.unblock()
        try await uploadGate.waitUntilBlocked(count: 3)
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
        let preparationGate = BlockingFakeUploadTransport()
        await preparationGate.unblock()
        let gate = BlockingFakeUploadTransport()
        let activity = UploadActivity()
        let uploader = MediaUploader(
            transport: ActivityTransport(gate: gate, activity: activity),
            materializer: GatedMaterializer(
                root: try fixtures.makeDirectory(),
                gate: preparationGate,
                activity: activity
            ),
            maxConcurrentUploads: 1
        )
        let first = try fixtures.writePDF(name: "first.pdf")
        let waiting = try fixtures.writePDF(name: "waiting.pdf")
        await uploader.enqueue(sources: [.file(first), .file(waiting)])
        try await gate.waitUntilBlocked()
        let state = await uploader.snapshot()
        await uploader.cancel(state.pending[1].id)
        #expect(await uploader.snapshot().pending.map(\.id) == [state.pending[0].id])
        await gate.unblock()
        try await waitForState(of: uploader) { $0.isEmpty }
        #expect(await activity.started == 1, "The cancelled waiting row must never enter preparation")
        await uploader.tearDown()
    }

    @Test("retry waits for an occupied slot and keeps its row position")
    func retryUsesAdmissionLimit() async throws {
        let gate = BlockingFakeUploadTransport(completionDelay: .milliseconds(100))
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
        try await gate.waitUntilBlocked()
        await uploader.retry(failed.failed[0].id)
        let state = await uploader.snapshot()
        #expect(state.pending.map(\.displayName) == ["failed.pdf", "active.pdf"])
        #expect(await gate.blockedCount == 1)
        await gate.unblock()
        try await waitForState(of: uploader) { $0.isEmpty }
        #expect(await gate.peakActiveCount == 1)
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
        try await gate.waitUntilBlocked()
        await uploader.tearDown()
        try await waitForUploadCondition { await activity.activeCount == 0 }
        #expect(await activity.started == 1)
        #expect(await uploader.snapshot().isEmpty)
        await uploader.enqueue(sources: [.file(source)])
        #expect(await activity.started == 1)
    }

    @Test("a cancelled active job keeps its slot until noncooperative work unwinds")
    func cancelledActiveJobKeepsItsSlot() async throws {
        let transport = SlowCancellationTransport()
        let uploader = fixtures.makeUploader(
            transport: transport,
            policy: makeAllowEverythingPolicy(),
            maxConcurrentUploads: 1
        )
        let first = try fixtures.writePDF(name: "cancelled.pdf")
        let second = try fixtures.writePDF(name: "second.pdf")
        await uploader.enqueue(sources: [.file(first), .file(second)])
        try await waitForUploadCondition { await transport.calls == 1 }
        let state = await uploader.snapshot()
        await uploader.cancel(state.pending[0].id)
        await uploader.enqueue(sources: [.file(try fixtures.writePDF(name: "third.pdf"))])
        await transport.unblock()
        try await waitForState(of: uploader) { $0.isEmpty }
        #expect(await transport.calls == 3)
        #expect(await transport.peak == 1)
        await uploader.tearDown()
    }
}

private actor SlowCancellationTransport: MediaUploadTransport {
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private var isOpen = false
    private var active = 0
    private(set) var calls = 0
    private(set) var peak = 0

    func upload(params: MediaCreateParams, fulfilling progress: Progress) async throws -> MediaWithEditContext {
        calls += 1
        active += 1
        peak = max(peak, active)
        defer { active -= 1 }
        if !isOpen { await withCheckedContinuation { waiters.append($0) } }
        // Model a transport that still owns the file briefly after cancellation.
        // This independent task deliberately does not inherit cancellation.
        try await Task.detached { try await Task.sleep(for: .milliseconds(100)) }.value
        try Task.checkCancellation()
        return MediaWithEditContext.fixture()
    }

    func unblock() {
        isOpen = true
        let pending = waiters
        waiters.removeAll()
        for waiter in pending { waiter.resume() }
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
