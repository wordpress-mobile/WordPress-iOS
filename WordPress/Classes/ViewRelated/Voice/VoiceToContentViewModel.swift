import Foundation
import AVFoundation
import WordPressKit
import WordPressShared

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

    var upgradeURL: URL? {
        featureInfo?.upgradeURL.flatMap(URL.init)
    }
    private var featureInfo: JetpackAssistantFeatureDetails?
    private var audioSession: AVAudioSession?
    private(set) var audioRecorder: AVAudioRecorder?
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
        WPAnalytics.track(.voiceToContentSheetShown)
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
            let info = try await service.getAssistantFeatureDetails()
            didFetchFeatureDetails(info)
        } catch {
            self.subtitle = Strings.errorMessageGeneric
            self.loadingState = .failed(message: error.localizedDescription) { [weak self] in
                self?.checkFeatureAvailability()
            }
        }
    }

    private func didFetchFeatureDetails(_ info: JetpackAssistantFeatureDetails) {
        self.featureInfo = info
        self.loadingState = nil
        if info.isSiteUpdateRequired == true {
            self.subtitle = Strings.subtitleRequestsAvailable + " 0"
            self.isEligible = false
        } else {
            let limit = info.getLocalizedRequestLimit()
            self.subtitle = Strings.subtitleRequestsAvailable + " \(limit)"
            self.isEligible = true
        }
    }

    func buttonUpgradeTapped(withUpgradeURL upgradeURL: URL) {
        WPAnalytics.track(.voiceToContentButtonUpgradeTapped)
        UIApplication.shared.open(upgradeURL)
    }

    // MARK: - Recording

    func buttonRecordTapped() {
        WPAnalytics.track(.voiceToContentButtonStartRecordingTapped)

        let recordingSession = AVAudioSession.sharedInstance()
        self.audioSession = recordingSession

        self.title = Strings.titleRecoding
        self.subtitle = Constants.recordingTimeLimit.minuteSecond

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
            audioRecorder.isMeteringEnabled = true
            audioRecorder.record()

            step = .recording
            startRecordingTimer()
        } catch {
            showError(error)
        }
    }

    private func startRecordingTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            guard let self, let audioRecorder = self.audioRecorder else { return }

            let timeRemaining = Constants.recordingTimeLimit - audioRecorder.currentTime

            guard timeRemaining > 0 else {
                WPAnalytics.track(.voiceToContentRecordingLimitReached)
                startProcessing()
                return
            }
            self.subtitle = Duration.seconds(timeRemaining)
                .formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2)))
        }
    }

    func buttonDoneRecordingTapped() {
        WPAnalytics.track(.voiceToContentButtonDoneTapped)

        startProcessing()
    }

    // MARK: - Processing

    private func startProcessing() {
        audioRecorder?.stop()
        audioSession = nil
        timer?.invalidate()

        title = Strings.titleProcessing
        subtitle = ""
        step = .processing

        processFile()
    }

    private func processFile() {
        guard let fileURL = audioRecorder?.url else {
            wpAssertionFailure("audio-recorder: file missing")
            return
        }
        Task {
            await self.process(fileURL: fileURL)
        }
    }

    @MainActor
    private func process(fileURL: URL) async {
        loadingState = .loading

        guard let api = blog.wordPressComRestApi() else {
            wpAssertionFailure("only available for .com sites")
            return
        }
        let service = JetpackAIServiceRemote(wordPressComRestApi: api, siteID: blog.dotComID ?? 0)
        do {
            let token = try await service.getAuthorizationToken()
            let transcription = try await service.transcribeAudio(from: fileURL, token: token)
            let content = try await service.makePostContent(fromPlainText: transcription, token: token)

            // "the __JETPACK_AI_ERROR__ is a special marker we ask GPT to add to
            // the request when it can’t understand the request for any reason"
            guard content != "__JETPACK_AI_ERROR__" else {
                // There is no point in retrying, but the transcription can still be useful.
                self.completion(transcription)
                return
            }
            self.completion(content)
        } catch {
            loadingState = .failed(message: error.localizedDescription) { [weak self] in
                self?.processFile()
            }
        }
    }

    func buttonCancelTapped() {
        WPAnalytics.track(.voiceToContentButtonCloseTapped)

        audioRecorder?.stop()
        audioRecorder = nil
    }

    // MARK: - AVAudioRecorderDelegate

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            audioRecorder?.stop()
            self.step = .welcome
            showError(VoiceToContentError.generic)
        }
    }

    // MARK: - Misc

    private func showError(_ error: Error) {
        errorAlertMessage = error.localizedDescription
        isShowingErrorAlert = true
    }
}

private enum VoiceToContentError: Error, LocalizedError {
    case generic
    case cantUnderstandRequest

    var errorDescription: String? {
        switch self {
        case .generic: return Strings.errorMessageGeneric
        case .cantUnderstandRequest: return Strings.errorMessageCantUnderstandRequest
        }
    }
}

private enum Constants {
    static let recordingTimeLimit: TimeInterval = 5 * 60 // 5 Minutes
}

private enum Strings {
    static let title = NSLocalizedString("postFromAudio.title", value: "Post from Audio", comment: "The screen title")
    static let errorMessageGeneric = NSLocalizedString("postFromAudio.errorMessage.generic", value: "Something went wrong", comment: "The screen subtitle in the error state")
    static let errorMessageCantUnderstandRequest = NSLocalizedString("postFromAudio.errorMessage.cantUnderstandRequest", value: "There were some issues processing the request. Please, try again later.", comment: "The AI failed to understand the request for any reasons")
    static let subtitleRequestsAvailable = NSLocalizedString("postFromAudio.subtitleRequestsAvailable", value: "Requests available:", comment: "The screen subtitle")
    static let titleRecoding = NSLocalizedString("postFromAudio.titleRecoding", value: "Recording…", comment: "The screen title when recording")
    static let titleProcessing = NSLocalizedString("postFromAudio.titleProcessing", value: "Processing…", comment: "The screen title when recording")
    static let unlimited = NSLocalizedString("postFromAudio.unlimited", value: "Unlimited", comment: "The value for the `requests available:` field for an unlimited plan")
}

extension JetpackAssistantFeatureDetails {
    func getLocalizedRequestLimit() -> String {
        // For a free plan, the root `requests-count` has to be used.
        if currentTier?.slug == "jetpack_ai_free" {
            return max(0, requestsLimit - requestsCount).description
        }
        // The backend uses `1` as an indicator of unlimited requests.
        if currentTier?.value == 1 {
            return Strings.unlimited
        }
        // The `usage-period.requests-count` is only valid for paid plans with
        // a limited number of requests.
        wpAssert(usagePeriod != nil, "missing usage-period")
        wpAssert(currentTier != nil, "missing current-tier")
        let requestsLimit = currentTier?.limit ?? requestsLimit
        let requestsCount = usagePeriod?.requestsCount ?? requestsCount
        return max(0, requestsLimit - requestsCount).description
    }
}

extension TimeInterval {
    var minuteSecond: String {
        String(format: "%02d:%02d", minute, second)
    }
    var minute: Int {
        Int((self / 60).truncatingRemainder(dividingBy: 60))
    }
    var second: Int {
        Int(truncatingRemainder(dividingBy: 60))
    }
}
