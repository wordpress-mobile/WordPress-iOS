/// Represents the core logic behind the Jetpack Remote Install.
///
/// This protocol is mainly used by `JetpackRemoteInstallViewController`, and allows the installation process
/// to be abstracted since there are many different ways to install the Jetpack plugin.
///
protocol JetpackRemoteInstallViewModel: AnyObject, JetpackRemoteInstallStateViewModel {

    // MARK: Properties

    /// The view controller can implement the closure to subscribe to every `state` changes.
    var onChangeState: ((JetpackRemoteInstallState) -> Void)? { get set }

    /// An enum that represents the current installation state.
    var state: JetpackRemoteInstallState { get }

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
}

// MARK: - Default Jetpack State View Model Implementation

extension JetpackRemoteInstallViewModel {
    var image: UIImage? {
        state.image
    }

    var titleText: String {
        state.title
    }

    var descriptionText: String {
        state.message
    }

    var buttonTitleText: String {
        state.buttonTitle
    }

    var hidesMainButton: Bool {
        state == .installing
    }

    var hidesLoadingIndicator: Bool {
        state != .installing
    }

    var hidesSupportButton: Bool {
        switch state {
        case .failure:
            return false
        default:
            return true
        }
    }
}

// MARK: - Jetpack Remote Install Events

enum JetpackRemoteInstallEvent {
    // User is seeing the initial installation screen.
    case initial

    // User initiated the Jetpack installation process.
    case start

    // Jetpack plugin is being installed.
    case loading

    // Jetpack plugin installation succeeded.
    case completed

    // Jetpack plugin installation failed.
    case failed(description: String, siteURLString: String)

    // User retried the Jetpack installation process.
    case retry

    // User initiated the Jetpack connection authorization.
    case connect

    // User initiated a login to authorize the Jetpack connection.
    case login
}
