import Testing
import Foundation
@testable import JetpackWatch_Watch_App

@Suite("RecordingViewModel")
@MainActor
struct RecordingViewModelTests {

    private func makeViewModel(siteID: Int64? = 1) -> (
        vm: RecordingViewModel,
        recorder: StubAudioRecorder,
        store: NoteStore,
        bridge: MockPhoneBridge
    ) {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RecordingVMTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let recorder = StubAudioRecorder(rootURL: tempDir)
        let store = NoteStore(rootURL: tempDir, audioRootURL: tempDir)
        let bridge = MockPhoneBridge(seedSites: [])
        let catalog = SiteCatalog(rootURL: tempDir)
        if let siteID {
            catalog.setSites([Site(id: siteID, name: "Test Site")])
            catalog.setDefaultSiteID(siteID)
        }
        let vm = RecordingViewModel(
            recorder: recorder,
            store: store,
            siteCatalog: catalog,
            phoneBridge: bridge
        )
        return (vm, recorder, store, bridge)
    }

    @Test func initial_state_is_idle() {
        let (vm, _, _, _) = makeViewModel()
        if case .idle = vm.state {} else { Issue.record("expected .idle"); return }
    }

    @Test func startRecording_transitions_state_and_starts_recorder() throws {
        let (vm, recorder, _, _) = makeViewModel()

        try vm.startRecording()

        if case .recording = vm.state {} else { Issue.record("expected .recording"); return }
        #expect(recorder.startedID != nil)
    }

    @Test func stopRecording_persists_note_and_hands_to_phone() async throws {
        let (vm, _, store, bridge) = makeViewModel()
        try vm.startRecording()

        try vm.stopRecording()

        // Allow the Task spawned in finalize() to flush.
        try await Task.sleep(nanoseconds: 50_000_000)

        if case .idle = vm.state {} else { Issue.record("expected .idle"); return }
        #expect(store.notes.count == 1)
        let note = try #require(store.notes.first)
        #expect(note.status == .queued)
        #expect(bridge.handedOffNoteIDs.contains(note.id))
    }

    @Test func startRecording_throws_when_no_default_site() {
        let (vm, _, _, _) = makeViewModel(siteID: nil)

        #expect(throws: RecordingViewModelError.noDefaultSite) {
            try vm.startRecording()
        }
    }

    @Test func auto_stop_callback_finalizes_the_note() async throws {
        let (vm, recorder, store, _) = makeViewModel()
        try vm.startRecording()

        recorder.triggerAutoStop()
        try await Task.sleep(nanoseconds: 50_000_000)

        if case .idle = vm.state {} else { Issue.record("expected .idle"); return }
        #expect(store.notes.count == 1)
        #expect(store.notes.first?.status == .queued)
    }
}

@MainActor
final class StubAudioRecorder: AudioRecorder {
    var startedID: UUID?
    var stopped = false
    var cancelled: [UUID] = []
    private var autoStop: (() -> Void)?

    override func start(id: UUID, onAutoStop: @escaping () -> Void) throws {
        startedID = id
        autoStop = onAutoStop
    }

    override func stop() -> URL? {
        stopped = true
        guard let id = startedID else { return nil }
        return fileURL(for: id)
    }

    override func cancel(id: UUID) {
        cancelled.append(id)
    }

    func triggerAutoStop() {
        autoStop?()
    }
}
