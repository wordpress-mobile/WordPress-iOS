import Foundation
import AVFoundation
import WordPressKit

final class VoiceToContentViewModel: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published private(set) var state: State = .welcome
    @Published private(set) var duration: String = "0:00"
    private(set) var errorMessage: String?
    @Published var isShowingError = false

    private var audioSession: AVAudioSession?
    private var audioRecorder: AVAudioRecorder?
    private weak var timer: Timer?
    private let blog: Blog
    private let completion: (String) -> Void

    enum State {
        case welcome
        case recording
        case processing
    }

    enum VoiceError: Error, LocalizedError {
        case noPermissions

        var errorDescription: String? {
            switch self {
            case .noPermissions:
                return "Recording permission is missing"
            }
        }
    }

    deinit {
        timer?.invalidate()
    }

    init(blog: Blog, _ completion: @escaping (String) -> Void) {
        self.blog = blog
        self.completion = completion
    }

    // MARK: - Recording

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
                        self.showError(VoiceError.noPermissions)
                    }
                }
            }
        } catch {
            showError(error)
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
            showError(error)
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
        startProcessing()
    }

    // MARK: - Processing

    private func startProcessing() {
        guard let fileURL = audioRecorder?.url else {
            wpAssertionFailure("audio-recorder: file missing")
            return
        }
        audioRecorder?.stop()
        audioRecorder = nil
        audioSession = nil

        state = .processing
        Task {
            await self.process(fileURL: fileURL)
        }
    }

    @MainActor
    private func process(fileURL: URL) async {
        guard let api = blog.wordPressComRestApi() else {
            wpAssertionFailure("only available for .com sites")
            return
        }
        let service = JetpackAIServiceRemote(wordPressComRestApi: api, siteID: blog.dotComID ?? 0)
        do {
            let token = try await service.getAuthorizationToken()
            // TODO: this doesn't seem to handle 401 and other "error" status codes correctly
            let transcription = try await service.transcribeAudio(from: fileURL, token: token)
            let content = try await service.makePostContent(fromPlainText: transcription, token: token)

            self.completion(content)
        } catch {
            showError(error)
        }
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

    // MARK: - Misc

    private func showError(_ error: Error) {
        errorMessage = error.localizedDescription
        isShowingError = true
    }
}
