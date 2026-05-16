import Foundation
import Testing
import UniformTypeIdentifiers
import WordPressAPI
@testable import WordPressMediaLibrary

@MainActor
@Suite("MediaLibraryViewModel uploads")
struct MediaLibraryViewModelUploadsTests {
    // MARK: - Helpers

    private func makeViewModel(
        uploader: MediaUploader,
        tracker: any MediaTracker = MockMediaTracker()
    ) -> MediaLibraryViewModel {
        MediaLibraryViewModel(tracker: tracker, uploader: uploader)
    }

    // MARK: - bannerSummary

    @Test("bannerSummary is nil when uploader state is empty")
    func bannerSummaryNilWhenEmpty() async throws {
        let uploader = MediaUploader(transport: FakeUploadTransport(), policy: makeAllowEverythingPolicy())
        let vm = makeViewModel(uploader: uploader)
        // One yield to let the observer task pick up the initial snapshot.
        await Task.yield()
        #expect(vm.bannerSummary == nil)
    }

    @Test("bannerSummary derives counts from pending + failed")
    func bannerSummaryDerivesCounts() async throws {
        // First response fails; second blocks so it stays pending.
        let blockingFake = BlockingAndThenFailFakeUploadTransport()
        await blockingFake.configureFirstCallAsFailure(URLError(.timedOut))
        let uploader = MediaUploader(transport: blockingFake, policy: makeAllowEverythingPolicy())

        let url1 = try writeTempPDF(name: "fail-banner.pdf")
        let url2 = try writeTempPDF(name: "pending-banner.pdf")
        defer {
            try? FileManager.default.removeItem(at: url1.deletingLastPathComponent())
            try? FileManager.default.removeItem(at: url2.deletingLastPathComponent())
        }

        // Enqueue both sources.
        await uploader.enqueue(sources: [.file(url1)])
        // Wait for the first to fail.
        try await Task.sleep(nanoseconds: 200_000_000)
        // Second stays pending (BlockingAndThenFailFakeUploadTransport blocks).
        await uploader.enqueue(sources: [.file(url2)])
        await Task.yield()

        let vm = makeViewModel(uploader: uploader)
        try await Task.sleep(nanoseconds: 50_000_000)

        let summary = vm.bannerSummary
        #expect(summary != nil)
        #expect(summary?.failedCount == 1)
        #expect(summary?.pendingCount == 1)

        // Unblock so the test tears down cleanly.
        await blockingFake.unblock()
    }

    // MARK: - enqueue analytics

    @Test("enqueue(.file PDF) fires mediaLibraryAdded(source: .otherApps, kind: .document)")
    func enqueueFilePDFFiresAnalytics() async throws {
        let tracker = RecordingMediaTracker()
        let uploader = MediaUploader(transport: FakeUploadTransport(), policy: makeAllowEverythingPolicy())
        let vm = makeViewModel(uploader: uploader, tracker: tracker)

        let url = try writeTempPDF(name: "doc.pdf")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        await vm.enqueue(sources: [.file(url)])

        #expect(tracker.events.count == 1)
        if case .mediaLibraryAdded(let source, let kind) = tracker.events[0] {
            #expect(source == .otherApps)
            #expect(kind == .document)
        } else {
            Issue.record("Expected .mediaLibraryAdded event")
        }
    }

    @Test("enqueue(.file IMG_1234.jpg) fires mediaLibraryAdded(source: .otherApps, kind: .image)")
    func enqueueFileJPEGFiresAnalytics() async throws {
        let tracker = RecordingMediaTracker()
        let uploader = MediaUploader(transport: FakeUploadTransport(), policy: makeAllowEverythingPolicy())
        let vm = makeViewModel(uploader: uploader, tracker: tracker)

        // Even without real JPEG content, UTType(filenameExtension:) maps .jpg to .jpeg
        // which conforms to .image.
        let url = try writeTempJPEG(name: "IMG_1234.jpg")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        await vm.enqueue(sources: [.file(url)])

        #expect(tracker.events.count == 1)
        if case .mediaLibraryAdded(let source, let kind) = tracker.events[0] {
            #expect(source == .otherApps)
            #expect(kind == .image)
        } else {
            Issue.record("Expected .mediaLibraryAdded event")
        }
    }

    @Test("enqueue(.file IMG_1234.mov) fires mediaLibraryAdded(source: .otherApps, kind: .video)")
    func enqueueFileMOVFiresAnalytics() async throws {
        let tracker = RecordingMediaTracker()
        let uploader = MediaUploader(transport: FakeUploadTransport(), policy: makeAllowEverythingPolicy())
        let vm = makeViewModel(uploader: uploader, tracker: tracker)

        let url = try writeTempMOV(name: "IMG_1234.mov")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        await vm.enqueue(sources: [.file(url)])

        #expect(tracker.events.count == 1)
        if case .mediaLibraryAdded(let source, let kind) = tracker.events[0] {
            #expect(source == .otherApps)
            #expect(kind == .video)
        } else {
            Issue.record("Expected .mediaLibraryAdded event")
        }
    }

    @Test("enqueue fires mediaLibraryAdded for each picked source")
    func enqueueMultipleSourcesFiresMultipleEvents() async throws {
        let tracker = RecordingMediaTracker()
        let uploader = MediaUploader(transport: FakeUploadTransport(), policy: makeAllowEverythingPolicy())
        let vm = makeViewModel(uploader: uploader, tracker: tracker)

        let jpgURL = try writeTempJPEG(name: "photo.jpg")
        let pdfURL = try writeTempPDF(name: "doc.pdf")
        defer {
            try? FileManager.default.removeItem(at: jpgURL.deletingLastPathComponent())
            try? FileManager.default.removeItem(at: pdfURL.deletingLastPathComponent())
        }

        await vm.enqueue(sources: [.file(jpgURL), .file(pdfURL)])

        #expect(tracker.events.count == 2)
        let kinds = tracker.events.compactMap { event -> MediaKind? in
            if case .mediaLibraryAdded(_, let kind) = event { return kind }
            return nil
        }
        #expect(kinds.contains(.image))
        #expect(kinds.contains(.document))
    }

    // MARK: - retryUpload

    @Test("retryUpload fires mediaLibraryUploadRetried then delegates to uploader")
    func retryUploadFiresAnalytics() async throws {
        let fakeTransport = FakeUploadTransport()
        await fakeTransport.setResponses([.failure(URLError(.timedOut))])
        let uploader = MediaUploader(transport: fakeTransport, policy: makeAllowEverythingPolicy())
        let tracker = RecordingMediaTracker()
        let vm = makeViewModel(uploader: uploader, tracker: tracker)

        let url = try writeTempPDF(name: "retry.pdf")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        await vm.enqueue(sources: [.file(url)])
        try await Task.sleep(nanoseconds: 200_000_000)

        let state = await uploader.snapshot()
        guard let failedID = state.failed.first?.id else {
            Issue.record("Expected a failed upload")
            return
        }

        await vm.retryUpload(failedID)

        let retriedEvents = tracker.events.filter {
            if case .mediaLibraryUploadRetried = $0 { return true }
            return false
        }
        #expect(retriedEvents.count == 1)

        // The item should now be pending (retry moved it back).
        let afterState = await uploader.snapshot()
        #expect(afterState.failed.isEmpty || afterState.pending.count >= 1)
    }

    // MARK: - dismissUpload

    @Test("dismissUpload does not fire analytics")
    func dismissUploadNoAnalytics() async throws {
        let fakeTransport = FakeUploadTransport()
        await fakeTransport.setResponses([.failure(URLError(.timedOut))])
        let uploader = MediaUploader(transport: fakeTransport, policy: makeAllowEverythingPolicy())
        let tracker = RecordingMediaTracker()
        let vm = makeViewModel(uploader: uploader, tracker: tracker)

        let url = try writeTempPDF(name: "dismiss.pdf")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        await vm.enqueue(sources: [.file(url)])
        try await Task.sleep(nanoseconds: 200_000_000)

        let state = await uploader.snapshot()
        guard let failedID = state.failed.first?.id else {
            Issue.record("Expected a failed upload")
            return
        }

        // Clear events accumulated during enqueue.
        tracker.events.removeAll()

        await vm.dismissUpload(failedID)

        #expect(tracker.events.isEmpty)
    }

    // MARK: - Pre-existing uploader state

    @Test("bannerSummary is non-nil immediately after init when uploader already has pending work")
    func bannerSummaryReflectsExistingPendingWork() async throws {
        let blocking = BlockingFakeUploadTransport()
        let uploader = MediaUploader(transport: blocking, policy: makeAllowEverythingPolicy())

        let url = try writeTempPDF(name: "pre-existing.pdf")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        // Enqueue before constructing the VM so the snapshot already has pending work.
        await uploader.enqueue(sources: [.file(url)])
        await Task.yield()

        let vm = makeViewModel(uploader: uploader)
        // One yield to let the observer Task pick up snapshot() on init.
        await Task.yield()
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(vm.bannerSummary != nil)
        #expect(vm.bannerSummary?.pendingCount == 1)

        await blocking.unblock()
    }
}
