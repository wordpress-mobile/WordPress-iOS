import WordPressAuthenticator

/// Controls the Jetpack Remote Install flow for Jetpack-connected self-hosted sites.
///
/// A site can establish a Jetpack connection through individual Jetpack plugins, but the site may not have
/// the full Jetpack plugin. This covers the logic behind the plugin installation process, and will stop the
/// process before proceeding to the Jetpack connection step (since the site is already connected).
///
class WPComJetpackRemoteInstallViewModel {

    // MARK: Dependencies

    private let service: PluginJetpackProxyService
    private let tracker: EventTracker

    /// For request cancellation purposes.
    private var progress: Progress? = nil

    // MARK: Properties

    // The flow should always complete after the plugin is installed.
    let shouldConnectToJetpack = false

    let supportSourceTag: WordPressSupportSourceTag? = .jetpackFullPluginInstallErrorSourceTag

    var onChangeState: ((JetpackRemoteInstallState, JetpackRemoteInstallStateViewModel) -> Void)? = nil

    private(set) var state: JetpackRemoteInstallState = .install {
        didSet {
            onChangeState?(state, stateViewModel)
        }
    }

    // MARK: Methods

    init(service: PluginJetpackProxyService = .init(),
         tracker: EventTracker = DefaultEventTracker()) {
        self.service = service
        self.tracker = tracker
    }
}

// MARK: - View Model Implementation

extension WPComJetpackRemoteInstallViewModel: JetpackRemoteInstallViewModel {
    func viewReady() {
        // set the initial state & trigger the callback.
        state = .install
    }

    func installJetpack(for blog: Blog, isRetry: Bool) {
        // Ensure that the blog is accessible through a WP.com account,
        // and doesn't already have the Jetpack plugin.
        guard let siteID = blog.dotComID?.intValue,
              blog.jetpackIsConnectedWithoutFullPlugin else {
            // In this case, let's do nothing for now. Falling to this state should be a logic error.
            return
        }

        // trigger the loading state.
        state = .installing

        progress = service.installPlugin(for: siteID, pluginSlug: Constants.jetpackSlug, active: true) { [weak self] result in
            switch result {
            case .success:
                self?.state = .success
            case .failure(let error):
                DDLogError("Error: Jetpack plugin installation via proxy failed. \(error.localizedDescription)")
                let installError = JetpackInstallError(title: error.localizedDescription, type: .unknown)
                self?.state = .failure(installError)
            }
        }
    }

    func track(_ event: JetpackRemoteInstallEvent) {
        switch event {
        case .initial, .loading:
            tracker.track(.jetpackInstallFullPluginViewed, properties: ["status": state.statusForTracks])
        case .failed(let description, _):
            tracker.track(.jetpackInstallPluginModalViewed,
                          properties: ["status": state.statusForTracks, "description": description])
        case .cancel:
            tracker.track(.jetpackInstallFullPluginCancelTapped, properties: ["status": state.statusForTracks])
        case .start:
            tracker.track(.jetpackInstallFullPluginInstallTapped)
        case .retry:
            tracker.track(.jetpackInstallFullPluginRetryTapped)
        case .completePrimaryButtonTapped:
            tracker.track(.jetpackInstallFullPluginDoneTapped)
        case .completed:
            tracker.track(.jetpackInstallFullPluginCompleted)
        default:
            break
        }
    }

    /// NOTE: There's no guarantee that the plugin installation will be properly cancelled.
    /// We *might* be able to cancel if the request hasn't been fired; but if it has, it'll probably succeed.
    ///
    /// An alternative would be to have a listener that checks if installation completes after cancellation,
    /// and fires background request to uninstall the plugin. But this will not be implemented now.
    func cancelTapped() {
        progress?.cancel()
        progress = nil
    }
}

// MARK: - Private Helpers

private extension WPComJetpackRemoteInstallViewModel {

    enum Constants {
        // The identifier for the Jetpack plugin, used for the proxied .org plugin endpoint.
        static let jetpackSlug = "jetpack"

        static let successDescriptionText = NSLocalizedString(
            "jetpack.install-flow.success.description",
            value: "Ready to use this site with the app.",
            comment: "The description text shown after the user has successfully installed the Jetpack plugin."
        )

        static let successButtonTitleText = NSLocalizedString(
            "jetpack.install-flow.success.primaryButtonText",
            value: "Done",
            comment: "Title of the primary button shown after the Jetpack plugin has been installed. "
                + "Tapping on the button dismisses the installation screen."
        )
    }

    // State view model overrides.
    var stateViewModel: JetpackRemoteInstallStateViewModel {
        return .init(
            state: state,
            descriptionText: (state == .success ? Constants.successDescriptionText : state.message),
            buttonTitleText: (state == .success ? Constants.successButtonTitleText : state.buttonTitle)
        )
    }
}

extension WordPressSupportSourceTag {
    static var jetpackFullPluginInstallErrorSourceTag: WordPressSupportSourceTag {
        .init(name: "jetpackInstallFullPluginError", origin: "origin:jp-install-full-plugin-error")
    }
}

// MARK: - Tracking Helpers

private extension JetpackRemoteInstallState {
    var statusForTracks: String {
        switch self {
        case .install:
            return "initial"
        case .installing:
            return "loading"
        case .failure:
            return "error"
        default:
            return String()
        }
    }
}
