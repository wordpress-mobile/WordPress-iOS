import Foundation
import Combine

enum RecordingViewModelError: Error, Equatable, Sendable {
    case noDefaultSite
    case alreadyRecording
    case storeFailed(String)
}

enum RecordingState: Equatable, Sendable {
    case idle
    case recording(noteID: UUID, startedAt: Date)
}

@MainActor
final class RecordingViewModel: ObservableObject {
    @Published private(set) var state: RecordingState = .idle
    @Published private(set) var lastError: RecordingViewModelError?

    private let recorder: AudioRecorder
    private let store: NoteStore
    private let siteCatalog: SiteCatalog
    private let phoneBridge: any PhoneBridge

    init(
        recorder: AudioRecorder,
        store: NoteStore,
        siteCatalog: SiteCatalog,
        phoneBridge: any PhoneBridge
    ) {
        self.recorder = recorder
        self.store = store
        self.siteCatalog = siteCatalog
        self.phoneBridge = phoneBridge
    }

    func startRecording() throws {
        if case .recording = state { throw RecordingViewModelError.alreadyRecording }
        guard siteCatalog.defaultSiteID != nil else {
            throw RecordingViewModelError.noDefaultSite
        }

        let id = UUID()
        let startedAt = Date()
        try recorder.start(id: id) { [weak self] in
            Task { @MainActor [weak self] in
                try? self?.finalize()
            }
        }
        state = .recording(noteID: id, startedAt: startedAt)
    }

    func stopRecording() throws {
        if case .recording = state {
            _ = recorder.stop()
            try finalize()
        }
    }

    private func finalize() throws {
        guard case let .recording(id, startedAt) = state else { return }
        guard let siteID = siteCatalog.defaultSiteID else {
            state = .idle
            return
        }
        let duration = Int(Date().timeIntervalSince(startedAt))
        let note = VoiceNote(
            id: id,
            createdAt: startedAt,
            siteID: siteID,
            audioFilename: "\(id.uuidString).m4a",
            durationSeconds: duration,
            status: .queued,
            statusReason: nil,
            postID: nil
        )
        do {
            try store.add(note)
        } catch {
            recorder.cancel(id: id)
            watchLogger.error("RecordingViewModel: store.add failed: \(error, privacy: .public)")
            lastError = .storeFailed(error.localizedDescription)
            state = .idle
            return
        }
        let audioURL = recorder.fileURL(for: id)
        let bridge = phoneBridge
        Task { await bridge.handOff(noteID: id, audioURL: audioURL, siteID: siteID) }
        state = .idle
    }
}
