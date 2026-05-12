import Foundation
import AVFoundation
import Combine

enum AudioRecorderError: Error, Sendable {
    case failedToStart
}

/// Wraps AVAudioRecorder for the Watch. Produces AAC/m4a at 32 kbps mono /
/// 16 kHz. Hard cap: 5 minutes (300 s). Subclass-friendly for testing.
@MainActor
class AudioRecorder: NSObject, ObservableObject {
    static let maximumDuration: TimeInterval = 300

    static let recordSettings: [String: Any] = [
        AVFormatIDKey:           kAudioFormatMPEG4AAC,
        AVNumberOfChannelsKey:    1,
        AVSampleRateKey:          16_000.0,
        AVEncoderBitRateKey:      32_000,
        AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
    ]

    @Published private(set) var isRecording: Bool = false
    @Published private(set) var currentDuration: TimeInterval = 0

    private let rootURL: URL
    private var recorder: AVAudioRecorder?
    private var currentID: UUID?
    private var timer: Timer?
    private var onAutoStop: (() -> Void)?

    init(rootURL: URL) {
        self.rootURL = rootURL
        super.init()
    }

    func fileURL(for id: UUID) -> URL {
        rootURL.appendingPathComponent("\(id.uuidString).m4a")
    }

    /// Throws if mic permission is denied or AVAudioRecorder can't start.
    /// Auto-stops at `maximumDuration`; `onAutoStop` runs on the main actor.
    func start(id: UUID, onAutoStop: @escaping () -> Void) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [])
        try session.setActive(true)

        let url = fileURL(for: id)
        let r = try AVAudioRecorder(url: url, settings: Self.recordSettings)
        r.delegate = self
        guard r.record(forDuration: Self.maximumDuration) else {
            throw AudioRecorderError.failedToStart
        }
        self.recorder = r
        self.currentID = id
        self.onAutoStop = onAutoStop
        self.isRecording = true
        self.currentDuration = 0

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let recorder = self.recorder else { return }
                self.currentDuration = recorder.currentTime
            }
        }
    }

    /// Stops the current recording. Returns the final URL or nil.
    @discardableResult
    func stop() -> URL? {
        guard let recorder, let id = currentID else { return nil }
        recorder.stop()
        let url = fileURL(for: id)
        cleanup()
        return url
    }

    /// Aborts recording for `id` and deletes any partial file on disk.
    func cancel(id: UUID) {
        if currentID == id {
            recorder?.stop()
            cleanup()
        }
        let url = fileURL(for: id)
        try? FileManager.default.removeItem(at: url)
    }

    private func cleanup() {
        timer?.invalidate()
        timer = nil
        recorder = nil
        currentID = nil
        onAutoStop = nil
        isRecording = false
        currentDuration = 0
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            let callback = self.onAutoStop
            self.cleanup()
            callback?()
        }
    }
}
