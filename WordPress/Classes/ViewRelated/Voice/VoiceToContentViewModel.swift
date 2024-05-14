import Foundation
import AVFoundation

final class VoiceToContentViewModel: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var state: State = .welcome
    @Published var duration: String = "0:00"
    @Published var errorMessage: String?

    private var audioSession: AVAudioSession?
    private var audioRecorder: AVAudioRecorder?
    private weak var timer: Timer?

    enum State {
        case welcome
        case recording
        case processing
    }

    deinit {
        timer?.invalidate()
    }

    func buttonRecordTapped() {
        let recordingSession = AVAudioSession.sharedInstance()
        self.audioSession = recordingSession

        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [weak self] allowed in
                guard let self else { return }
                DispatchQueue.main.async {
                    if allowed {
                        self.startRecording()
                    } else {
                        self.errorMessage = "Recordings permission missing"
                    }
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func startRecording() {
        let filename = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let audioRecorder = try AVAudioRecorder(url: filename, settings: settings)
            self.audioRecorder = audioRecorder

            audioRecorder.delegate = self
            audioRecorder.record()

            state = .recording
            startRecordingTimer()
        } catch {
            // TODO: handle error
            fatalError(error.localizedDescription)
        }
    }

    private func startRecordingTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            guard let self else { return }
            if #available(iOS 16.0, *) {
                self.duration = Duration.seconds(self.audioRecorder?.currentTime ?? 0)
                    .formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2, fractionalSecondsLength: 2)))
            } else {
                // TODO: Make this feature available on iOS 16+?
            }
        }
    }

    func buttonDoneRecordingTapped() {
        guard let fileURL = audioRecorder?.url else {
            wpAssertionFailure("audio-recorder: file missing")
            return
        }
        audioRecorder?.stop()
        audioRecorder = nil
        audioSession = nil

        NSLog("fileURL: \(fileURL))")

        state = .processing
    }

    func buttonCancelTapped() {
        audioRecorder?.stop()
        audioRecorder = nil
    }

    // MARK: - AVAudioRecorderDelegate

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        // TODO: Handle error when iOS finished recording due to an interruption
        if !flag {
            audioRecorder?.stop()
            self.state = .welcome
        }
    }
}
