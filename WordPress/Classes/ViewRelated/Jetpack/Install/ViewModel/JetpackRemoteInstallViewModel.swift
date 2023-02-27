import WordPressAuthenticator

/// Represents the core logic behind the Jetpack Remote Install.
///
/// This protocol is mainly used by `JetpackRemoteInstallViewController`, and allows the installation process
/// to be abstracted since there are many different ways to install the Jetpack plugin.
///
protocol JetpackRemoteInstallViewModel: AnyObject {

    // MARK: Properties

    /// The view controller can implement the closure to subscribe to every `state` changes.
    var onChangeState: ((JetpackRemoteInstallState, JetpackRemoteInstallStateViewModel) -> Void)? { get set }

    /// An enum that represents the current installation state.
    var state: JetpackRemoteInstallState { get }

    /// Whether the install flow should continue with establishing a Jetpack connection for the site.
    var shouldConnectToJetpack: Bool { get }

    /// The source tag to be used when the user opens the Support screen in case of installation errors.
    var supportSourceTag: WordPressSupportSourceTag? { get }

    // MARK: Methods

    /// Called by the view controller when it's ready to receive user interaction.
    func viewReady()

    /// Starts the Jetpack plugin installation.
    ///
    /// The progress will be reflected into the `state` object, which should be subscribed by
    /// the view controller through the `onChangeState` method.
    ///
    /// - Parameters:
    ///   - blog: The Blog to install the Jetpack plugin.
    ///   - isRetry: For tracking purposes. True means this is a retry attempt.
    func installJetpack(for blog: Blog, isRetry: Bool)

    /// Abstracted tracking implementation for the `JetpackRemoteInstallEvent`.
    ///
    /// - Parameter event: The events to track. See `JetpackRemoteInstallEvent` for more info.
    func track(_ event: JetpackRemoteInstallEvent)

    /// Called by the view controller when the user taps Cancel.
    ///
    /// This allows the view model to perform necessary operation cleanups, but note that
    /// the actual navigation actions upon cancellation should be controlled by `JetpackRemoteInstallDelegate`.
    func cancelTapped()
}

// MARK: - Default Init Jetpack State View Model

extension JetpackRemoteInstallStateViewModel {

    init(state: JetpackRemoteInstallState,
         image: UIImage? = nil,
         titleText: String? = nil,
         descriptionText: String? = nil,
         buttonTitleText: String? = nil,
         hidesLoadingIndicator: Bool? = nil,
         hidesSupportButton: Bool? = nil) {
        self.image = image ?? state.image
        self.titleText = titleText ?? state.title
        self.descriptionText = descriptionText ?? state.message
        self.buttonTitleText = buttonTitleText ?? state.buttonTitle
        self.hidesLoadingIndicator = hidesLoadingIndicator ?? (state != .installing)
        self.hidesSupportButton = hidesSupportButton ?? {
            switch state {
            case .failure:
                return false
            default:
                return true
            }
        }()
    }

}

// MARK: - Jetpack Remote Install Events

enum JetpackRemoteInstallEvent {
    /// User is seeing the initial installation screen.
    case initial

    /// User initiated the Jetpack installation process.
    case start

    /// Jetpack plugin is being installed.
    case loading

    /// Jetpack plugin installation succeeded.
    case completed

    /// Jetpack plugin installation failed.
    case failed(description: String, siteURLString: String)

    /// User retried the Jetpack installation process.
    case retry

    /// User cancelled the installation process.
    case cancel

    /// User tapped the primary button in the completed state.
    case completePrimaryButtonTapped

    /// User initiated the Jetpack connection authorization.
    case connect

    /// User initiated a login to authorize the Jetpack connection.
    case login
}
