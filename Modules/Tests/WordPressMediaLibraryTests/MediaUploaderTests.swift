import Foundation
import Testing
import UIKit
import UniformTypeIdentifiers
import WordPressAPI
import WordPressAPIInternal
@testable import WordPressMediaLibrary

@Suite("MediaUploader")
struct MediaUploaderTests {
    @Test("enqueue moves source through to pending state and fires upload")
    func enqueueProducesPending() async throws {
        let fakeTransport = FakeUploadTransport()
        let uploader = MediaUploader(transport: fakeTransport, policy: makeAllowEverythingPolicy())

        let sourceURL = try writeTempPDF(name: "doc.pdf")
        defer { try? FileManager.default.removeItem(at: sourceURL) }

        let stateBefore = await uploader.snapshot()
        #expect(stateBefore.pending.isEmpty)

        await uploader.enqueue(sources: [.file(sourceURL)])

        // Wait a beat for the upload task to start and complete.
        try await Task.sleep(nanoseconds: 100_000_000)

        let uploadCount = await fakeTransport.uploadCount
        #expect(uploadCount == 1)
    }

    @Test("success path removes pending entry")
    func successRemovesPending() async throws {
        let fakeTransport = FakeUploadTransport()
        let uploader = MediaUploader(transport: fakeTransport, policy: makeAllowEverythingPolicy())

        let sourceURL = try writeTempPDF(name: "success.pdf")
        defer { try? FileManager.default.removeItem(at: sourceURL) }

        await uploader.enqueue(sources: [.file(sourceURL)])
        try await Task.sleep(nanoseconds: 200_000_000)

        let state = await uploader.snapshot()
        #expect(state.pending.isEmpty)
        #expect(state.failed.isEmpty)
    }

    @Test("failure surfaces in failed list with localized message")
    func failureSurfacesInFailed() async throws {
        let fakeTransport = FakeUploadTransport()
        await fakeTransport.setResponses([.failure(URLError(.timedOut))])
        let uploader = MediaUploader(transport: fakeTransport, policy: makeAllowEverythingPolicy())

        let sourceURL = try writeTempPDF(name: "fail.pdf")
        defer { try? FileManager.default.removeItem(at: sourceURL) }

        await uploader.enqueue(sources: [.file(sourceURL)])
        try await Task.sleep(nanoseconds: 200_000_000)

        let state = await uploader.snapshot()
        #expect(state.pending.isEmpty)
        #expect(state.failed.count == 1)
        #expect(!state.failed[0].errorMessage.isEmpty)
    }

    @Test("cancel removes pending silently without moving to failed")
    func cancelRemovesSilently() async throws {
        let blocking = BlockingFakeUploadTransport()
        let uploader = MediaUploader(transport: blocking, policy: makeAllowEverythingPolicy())

        let sourceURL = try writeTempPDF(name: "cancel.pdf")
        defer { try? FileManager.default.removeItem(at: sourceURL) }

        await uploader.enqueue(sources: [.file(sourceURL)])
        // Yield so the Task spawned by spawnUploadTask gets to run and block.
        await Task.yield()

        let stateDuring = await uploader.snapshot()
        #expect(stateDuring.pending.count == 1)

        let uploadID = stateDuring.pending[0].id
        await uploader.cancel(uploadID)
        // Signal the blocking upload to unblock (it'll be cancelled already).
        await blocking.unblock()

        let stateAfter = await uploader.snapshot()
        #expect(stateAfter.pending.isEmpty)
        #expect(stateAfter.failed.isEmpty)
    }

    @Test("retry rebuilds pending from a failed entry")
    func retryRebuildsPending() async throws {
        let fakeTransport = FakeUploadTransport()
        // First call fails, second succeeds.
        await fakeTransport.setResponses([.failure(URLError(.timedOut))])
        let uploader = MediaUploader(transport: fakeTransport, policy: makeAllowEverythingPolicy())

        let sourceURL = try writeTempPDF(name: "retry.pdf")
        defer { try? FileManager.default.removeItem(at: sourceURL) }

        await uploader.enqueue(sources: [.file(sourceURL)])
        try await Task.sleep(nanoseconds: 200_000_000)

        let failedState = await uploader.snapshot()
        #expect(failedState.failed.count == 1)
        #expect(failedState.failed[0].isRetryable)

        let failedID = failedState.failed[0].id
        await uploader.retry(failedID)

        let retryingState = await uploader.snapshot()
        #expect(retryingState.pending.count == 1)
        #expect(retryingState.failed.isEmpty)

        try await Task.sleep(nanoseconds: 200_000_000)

        let finalState = await uploader.snapshot()
        #expect(finalState.pending.isEmpty)
        #expect(finalState.failed.isEmpty)
    }

    @Test("retry on materialization-failure entry is no-op")
    func retryOnNonRetryableIsNoOp() async throws {
        // Use a policy that rejects all files to force a materialization failure.
        let rejectAll = MediaUploadPolicy(
            filePickerContentTypes: [.content],
            isAllowedForUpload: { _, _ in false },
            imageMaxDimension: nil,
            imageJpegQuality: 0.9,
            convertHEICToJPEG: true,
            videoMaxDurationSeconds: nil,
            videoExportPreset: "AVAssetExportPresetMediumQuality",
            videoOutputContentType: .mpeg4Movie,
            stripImageLocation: false
        )
        let fakeTransport = FakeUploadTransport()
        let uploader = MediaUploader(transport: fakeTransport, policy: rejectAll)

        let sourceURL = try writeTempPDF(name: "rejected.pdf")
        defer { try? FileManager.default.removeItem(at: sourceURL) }

        await uploader.enqueue(sources: [.file(sourceURL)])
        try await Task.sleep(nanoseconds: 100_000_000)

        let state = await uploader.snapshot()
        #expect(state.failed.count == 1)
        #expect(!state.failed[0].isRetryable)

        let failedID = state.failed[0].id
        await uploader.retry(failedID)

        let stateAfter = await uploader.snapshot()
        #expect(stateAfter.failed.count == 1)
    }

    @Test("dismiss removes failed entry")
    func dismissRemovesFailed() async throws {
        let fakeTransport = FakeUploadTransport()
        await fakeTransport.setResponses([.failure(URLError(.timedOut))])
        let uploader = MediaUploader(transport: fakeTransport, policy: makeAllowEverythingPolicy())

        let sourceURL = try writeTempPDF(name: "dismiss.pdf")
        defer { try? FileManager.default.removeItem(at: sourceURL) }

        await uploader.enqueue(sources: [.file(sourceURL)])
        try await Task.sleep(nanoseconds: 200_000_000)

        let failedState = await uploader.snapshot()
        #expect(failedState.failed.count == 1)
        let failedID = failedState.failed[0].id

        await uploader.dismiss(failedID)

        let afterState = await uploader.snapshot()
        #expect(afterState.failed.isEmpty)
    }

    @Test("cancelAllPending only acts on pending items")
    func cancelAllPendingOnlyActsOnPending() async throws {
        let blocking = BlockingFakeUploadTransport()
        let uploader = MediaUploader(transport: blocking, policy: makeAllowEverythingPolicy())

        let url1 = try writeTempPDF(name: "a.pdf")
        let url2 = try writeTempPDF(name: "b.pdf")
        defer {
            try? FileManager.default.removeItem(at: url1)
            try? FileManager.default.removeItem(at: url2)
        }

        await uploader.enqueue(sources: [.file(url1), .file(url2)])
        await Task.yield()

        let state = await uploader.snapshot()
        #expect(state.pending.count == 2)

        await uploader.cancelAllPending()
        await blocking.unblock()

        let afterState = await uploader.snapshot()
        #expect(afterState.pending.isEmpty)
        #expect(afterState.failed.isEmpty)
    }

    @Test("tearDown drains both lists and finishes the stream")
    func tearDownDrainsBothLists() async throws {
        let fakeTransport = FakeUploadTransport()
        await fakeTransport.setResponses([.failure(URLError(.timedOut))])
        let uploader = MediaUploader(transport: fakeTransport, policy: makeAllowEverythingPolicy())

        let failURL = try writeTempPDF(name: "fail-teardown.pdf")
        defer { try? FileManager.default.removeItem(at: failURL) }

        await uploader.enqueue(sources: [.file(failURL)])
        try await Task.sleep(nanoseconds: 200_000_000)

        let stateBefore = await uploader.snapshot()
        #expect(stateBefore.failed.count == 1)

        await uploader.tearDown()

        let stateAfter = await uploader.snapshot()
        #expect(stateAfter.isEmpty)

        // A newly subscribed stream after teardown should terminate immediately.
        var receivedStates = 0
        for await _ in uploader.statePublisher.values {
            receivedStates += 1
        }
        #expect(receivedStates == 0)
    }

    @Test("failure keeps its slot in submission order; later pending stays after")
    func failureKeepsSlotInOrder() async throws {
        // First upload fails; second blocks so it stays pending.
        let fakeTransport = BlockingAndThenFailFakeUploadTransport()
        await fakeTransport.configureFirstCallAsFailure(URLError(.timedOut))
        let uploader = MediaUploader(transport: fakeTransport, policy: makeAllowEverythingPolicy())

        let urlA = try writeTempPDF(name: "first.pdf")
        let urlB = try writeTempPDF(name: "second.pdf")
        defer {
            try? FileManager.default.removeItem(at: urlA.deletingLastPathComponent())
            try? FileManager.default.removeItem(at: urlB.deletingLastPathComponent())
        }

        await uploader.enqueue(sources: [.file(urlA)])
        try await Task.sleep(nanoseconds: 200_000_000)
        await uploader.enqueue(sources: [.file(urlB)])
        try await Task.sleep(nanoseconds: 150_000_000)

        let state = await uploader.snapshot()
        #expect(state.entries.count == 2)
        // First slot is the failed `first.pdf`; second slot is pending
        // `second.pdf`. The crucial bit is that `first.pdf` did NOT
        // migrate to the end after failing.
        if case .failed(let f) = state.entries[0] {
            #expect(f.displayName == "first.pdf")
        } else {
            Issue.record("first.pdf should be in slot 0 (failed) after failure")
        }
        if case .pending(let p) = state.entries[1] {
            #expect(p.displayName == "second.pdf")
        } else {
            Issue.record("second.pdf should be in slot 1 (pending)")
        }

        await fakeTransport.unblock()
    }

    @Test("UploadSource.materializationProgressWeight is 0.05 for on-device sources")
    func materializationProgressWeightLocalSources() async throws {
        let pdfURL = try writeTempPDF()
        defer { try? FileManager.default.removeItem(at: pdfURL.deletingLastPathComponent()) }

        let cases: [UploadSource] = [
            .photoLibrary(itemProvider: NSItemProvider(), suggestedName: nil, hint: .image),
            .cameraImage(UIImage(), capturedAt: Date()),
            .cameraVideo(pdfURL, capturedAt: Date()),
            .file(pdfURL)
        ]
        for source in cases {
            #expect(source.materializationProgressWeight == 0.05)
        }
    }

    @Test func materializationProgressWeight_remoteURL_splitsEvenly() {
        let remoteURL = UploadSource.remoteURL(
            .init(
                url: URL(string: "https://example.com/a.jpg")!,
                suggestedName: "a",
                contentType: .jpeg,
                caption: nil
            )
        )
        #expect(remoteURL.materializationProgressWeight == 0.5)
    }

    @Test func materializationProgressWeight_imagePlayground_isLight() {
        let imagePlayground = UploadSource.imagePlayground(
            URL(fileURLWithPath: "/tmp/x.heic"),
            suggestedName: "x"
        )
        #expect(imagePlayground.materializationProgressWeight == 0.05)
    }

    @Test("enqueue inserts the pending row before materialization completes")
    func rowAppearsBeforeMaterialization() async throws {
        let transport = FakeUploadTransport()
        let mock = MockMaterializer()
        let uploader = MediaUploader(
            transport: transport,
            materializer: mock,
            filePickerContentTypes: [.content]
        )

        let pdfURL = try writeTempPDF()
        defer { try? FileManager.default.removeItem(at: pdfURL.deletingLastPathComponent()) }

        await uploader.enqueue(sources: [.file(pdfURL)])

        // The row should be visible immediately; do not await materialization.
        let snapshot = await uploader.snapshot()
        #expect(snapshot.pending.count == 1)
        #expect(snapshot.failed.isEmpty)

        // Cancel to drain the in-flight Task before the test exits.
        if let id = snapshot.pending.first?.id {
            await uploader.cancel(id)
        }
    }

    @Test("stage progress feeds the row's overall progress (5% local weight)")
    func materializationProgressReachesUI() async throws {
        let transport = FakeUploadTransport()
        let mock = MockMaterializer()
        let uploader = MediaUploader(
            transport: transport,
            materializer: mock,
            filePickerContentTypes: [.content]
        )

        let pdfURL = try writeTempPDF()
        defer { try? FileManager.default.removeItem(at: pdfURL.deletingLastPathComponent()) }

        await uploader.enqueue(sources: [.file(pdfURL)])

        // Wait until the work Task has entered materialize.
        await mock.waitForStart()

        let stage = await mock.lastStageProgress
        #expect(stage != nil)
        stage?.completedUnitCount = 50

        // Re-read snapshot; the entry's overall progress should reflect
        // 50% of the 5% weight = 0.025.
        let snapshot = await uploader.snapshot()
        let row = try #require(snapshot.pending.first)
        #expect(abs(row.progress.fractionCompleted - 0.025) < 0.001)

        // Drain.
        if let id = snapshot.pending.first?.id {
            await uploader.cancel(id)
        }
    }

    @Test("cancel during materialization removes the row silently")
    func cancelDuringMaterialization() async throws {
        let transport = FakeUploadTransport()
        let mock = MockMaterializer()
        let uploader = MediaUploader(
            transport: transport,
            materializer: mock,
            filePickerContentTypes: [.content]
        )

        let pdfURL = try writeTempPDF()
        defer { try? FileManager.default.removeItem(at: pdfURL.deletingLastPathComponent()) }

        await uploader.enqueue(sources: [.file(pdfURL)])
        await mock.waitForStart()

        let snapshot = await uploader.snapshot()
        let id = try #require(snapshot.pending.first?.id)

        // Cancel while the mock is still blocked.
        await uploader.cancel(id)

        // Now let the mock resolve as success — it'll throw CancellationError
        // because of the checkCancellation inside MockMaterializer.
        let materialized = MaterializedUpload(
            tempFileURL: pdfURL,
            params: MediaCreateParams(filePath: pdfURL.path),
            kind: .document,
            displayName: pdfURL.lastPathComponent
        )
        await mock.complete(with: .success(materialized))

        // Allow the work Task to fully unwind.
        try await Task.sleep(for: .milliseconds(50))

        let after = await uploader.snapshot()
        #expect(after.pending.isEmpty)
        #expect(after.failed.isEmpty)
        let uploadCount = await transport.uploadCount
        #expect(uploadCount == 0)
    }

    @Test("cancel between materialize and upload removes the row AND the temp dir")
    func cancelBetweenMaterializeAndUploadCleansOrphan() async throws {
        let transport = BlockingFakeUploadTransport()
        let mock = MockMaterializer()
        let uploader = MediaUploader(
            transport: transport,
            materializer: mock,
            filePickerContentTypes: [.content]
        )

        // Create a real on-disk temp file the mock will return as the
        // materialized output. We assert this file (or its parent dir) is
        // gone after cancel.
        let realTemp = try writeTempFile(name: "fake-materialized.bin", content: Data("payload".utf8))
        let parentDir = realTemp.deletingLastPathComponent()
        defer { try? FileManager.default.removeItem(at: parentDir) }
        #expect(FileManager.default.fileExists(atPath: realTemp.path))

        let pdfURL = try writeTempPDF()
        defer { try? FileManager.default.removeItem(at: pdfURL.deletingLastPathComponent()) }

        await uploader.enqueue(sources: [.file(pdfURL)])
        await mock.waitForStart()

        let snapshot = await uploader.snapshot()
        let id = try #require(snapshot.pending.first?.id)

        // Resolve materialize with a successful materialized payload pointing
        // at our real on-disk file. The work Task hops back to the actor
        // (markMaterialized) AFTER this returns.
        let materialized = MaterializedUpload(
            tempFileURL: realTemp,
            params: MediaCreateParams(filePath: realTemp.path),
            kind: .document,
            displayName: realTemp.lastPathComponent
        )
        await mock.complete(with: .success(materialized))

        // Race: cancel ASAP — it may land before or after markMaterialized.
        // Either way, the orphan-cleanup path must remove the temp dir.
        await uploader.cancel(id)

        // Let the work Task fully unwind, plus any cleanup hops.
        try await Task.sleep(for: .milliseconds(100))

        let after = await uploader.snapshot()
        #expect(after.pending.isEmpty)
        #expect(after.failed.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: realTemp.path), "orphan temp dir leaked")

        // Drain the blocking transport in case it was reached.
        await transport.unblock()
    }

    @Test("materialization failure keeps its slot in submission order")
    func materializationFailureKeepsSlot() async throws {
        // Reject-all policy → first source's materialization fails.
        let rejectAll = MediaUploadPolicy(
            filePickerContentTypes: [.content],
            isAllowedForUpload: { _, _ in false },
            imageMaxDimension: nil,
            imageJpegQuality: 0.9,
            convertHEICToJPEG: true,
            videoMaxDurationSeconds: nil,
            videoExportPreset: "AVAssetExportPresetMediumQuality",
            videoOutputContentType: .mpeg4Movie,
            stripImageLocation: false
        )
        let transport = BlockingFakeUploadTransport()
        let uploader = MediaUploader(transport: transport, policy: rejectAll)

        let urlA = try writeTempPDF(name: "first.pdf")
        let urlB = try writeTempPDF(name: "second.pdf")
        defer {
            try? FileManager.default.removeItem(at: urlA.deletingLastPathComponent())
            try? FileManager.default.removeItem(at: urlB.deletingLastPathComponent())
        }

        await uploader.enqueue(sources: [.file(urlA)])
        try await Task.sleep(for: .milliseconds(150))
        await uploader.enqueue(sources: [.file(urlB)])
        try await Task.sleep(for: .milliseconds(150))

        let state = await uploader.snapshot()
        #expect(state.entries.count == 2)
        if case .failed(let f) = state.entries[0] {
            #expect(f.displayName == "first.pdf")
            #expect(!f.isRetryable)
        } else {
            Issue.record("first.pdf should be failed in slot 0")
        }
        if case .failed(let f) = state.entries[1] {
            // Reject-all means both fail at materialization.
            #expect(f.displayName == "second.pdf")
            #expect(!f.isRetryable)
        } else if case .pending(let p) = state.entries[1] {
            // Transport blocks if we ever reach upload, which we don't.
            Issue.record("second.pdf unexpectedly reached upload phase: \(p.displayName)")
        }

        await transport.unblock()
    }

    @Test("transport cancellation error is silent, not flipped to failed")
    func transportCancellationIsSilent() async throws {
        let transport = FakeUploadTransport()
        await transport.setResponses([.failure(URLError(.cancelled))])
        let uploader = MediaUploader(transport: transport, policy: makeAllowEverythingPolicy())

        let pdfURL = try writeTempPDF()
        defer { try? FileManager.default.removeItem(at: pdfURL.deletingLastPathComponent()) }

        await uploader.enqueue(sources: [.file(pdfURL)])
        try await Task.sleep(for: .milliseconds(200))

        let state = await uploader.snapshot()
        #expect(state.pending.isEmpty)
        #expect(state.failed.isEmpty, "transport cancellation should be silent, not failed")
    }
}
