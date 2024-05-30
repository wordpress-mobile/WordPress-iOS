import Foundation
import AVFoundation
import WordPressKit

final class VoiceToContentViewModel: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published private(set) var title: String = ""
    @Published private(set) var subtitle: String = ""

    @Published private(set) var isEligible: Bool?

    @Published private(set) var step: Step = .welcome
    @Published private(set) var loadingState: LoadingState?

    private(set) var errorAlertMessage: String?
    @Published var isShowingErrorAlert = false

    var isButtonRecordEnabled: Bool {
        if case .loading = loadingState {
            return false
        }
        guard let isEligible else {
            return false
        }
        return isEligible
    }

    private var audioSession: AVAudioSession?
    private var audioRecorder: AVAudioRecorder?
    private weak var timer: Timer?
    private let blog: Blog
    private let completion: (String) -> Void

    enum Step {
        /// The state in which the flow checks your eligibility and, if you are,
        /// presents a "Begin recording" button.
        case welcome
        case recording
        case processing
    }

    enum LoadingState {
        case loading
        case failed(message: String, onRetry: () -> Void)
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
        self.title = Strings.title
    }

    func onViewAppeared() {
        checkFeatureAvailability()
    }

    // MARK: - Welcome (Eligibility)

    private func checkFeatureAvailability() {
        Task {
            await self._checkFeatureAvailability()
        }
    }

    @MainActor
    private func _checkFeatureAvailability() async {
        self.loadingState = .loading
        self.subtitle = Strings.subtitleRequestsAvailable // Showing spinner instead of a number

        guard let api = blog.wordPressComRestApi() else {
            wpAssertionFailure("API not available")
            return
        }
        let service = JetpackAIServiceRemote(wordPressComRestApi: api, siteID: blog.dotComID ?? 0)
        do {
            if #available(iOS 16, *) {
                try await Task.sleep(for: .seconds(2))
            }

            let info = try await service.getAssistantFeatureDetails()
            didFetchFeatureDetails(info)
        } catch {
            self.subtitle = Strings.subtitleError
            self.loadingState = .failed(message: error.localizedDescription) { [weak self] in
                self?.checkFeatureAvailability()
            }
        }
    }

    private func didFetchFeatureDetails(_ info: JetpackAssistantFeatureDetails) {
        self.loadingState = nil
        if info.hasFeature, !info.isOverLimit {
            let requestLimit = info.currentTier?.limit ?? info.requestsLimit
            let requestsCount = (info.usagePeriod?.requestsCount ?? 0)
            let remainingRequestCount = max(0, requestLimit - requestsCount)
            let value = info.currentTier?.readableLimit ?? remainingRequestCount.description
            self.subtitle = Strings.subtitleRequestsAvailable + " \(value)"
            self.isEligible = true
        } else {
            self.subtitle = Strings.subtitleRequestsAvailable + " 0"
            self.isEligible = false
        }
    }

    func buttonUpgradeTapped() {
        // TODO: this does not work
        guard let siteURL = blog.url.flatMap(URL.init) else {
            return wpAssertionFailure("invalid blog URL")
        }
        let upgradeURL = siteURL.appendingPathComponent("/wp-admin/admin.php?page=my-jetpack#/add-jetpack-ai")
        UIApplication.shared.open(upgradeURL)
    }

    // MARK: - Recording

    func buttonRecordTapped() {
        let recordingSession = AVAudioSession.sharedInstance()
        self.audioSession = recordingSession

        self.title = Strings.titleRecoding
        self.subtitle = "00:00"

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

            step = .recording
            startRecordingTimer()
        } catch {
            showError(error)
        }
    }

    private func startRecordingTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            guard let self else { return }
            if #available(iOS 16.0, *) {
                self.subtitle = Duration.seconds(self.audioRecorder?.currentTime ?? 0)
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
        timer?.invalidate()

        title = Strings.titleProcessing
        subtitle = ""
        step = .processing
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
            self.step = .welcome
        }
    }

    // MARK: - Misc

    private func showError(_ error: Error) {
        errorAlertMessage = error.localizedDescription
        isShowingErrorAlert = true
    }
}

private enum Strings {
    static let title = NSLocalizedString("postFromAudio.title", value: "Post from Audio", comment: "The screen title")
    static let subtitleError = NSLocalizedString("postFromAudio.subtitleError", value: "Something went wrong", comment: "The screen subtitle in the error state")
    static let subtitleRequestsAvailable = NSLocalizedString("postFromAudio.subtitleRequestsAvailable", value: "Requests available:", comment: "The screen subtitle")
    static let titleRecoding = NSLocalizedString("postFromAudio.titleRecoding", value: "Recording…", comment: "The screen title when recording")
    static let titleProcessing = NSLocalizedString("postFromAudio.titleProcessing", value: "Processing…", comment: "The screen title when recording")
}
