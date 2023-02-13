/// Controls the Jetpack Remote Install flow for Jetpack-connected self-hosted sites.
///
/// A site can establish a Jetpack connection through individual Jetpack plugins, but the site may not have
/// the full Jetpack plugin. This covers the logic behind the plugin installation process, and will stop the
/// process before proceeding to the Jetpack connection step (since the site is already connected).
///
class WPComJetpackRemoteInstallViewModel {

    // MARK: Dependencies

    private let service: PluginJetpackProxyService

    // MARK: Properties

    // The flow should always complete after the plugin is installed.
    let shouldConnectToJetpack = false

    var onChangeState: ((JetpackRemoteInstallState, JetpackRemoteInstallStateViewData) -> Void)? = nil

    private(set) var state: JetpackRemoteInstallState = .install {
        didSet {
            onChangeState?(state, viewData)
        }
    }

    // MARK: Methods

    init(service: PluginJetpackProxyService = .init()) {
        self.service = service
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

        service.installPlugin(for: siteID, pluginSlug: Constants.jetpackSlug, active: true) { [weak self] result in
            switch result {
            case .success:
                self?.state = .success
            case .failure(let error):
                DDLogError("Error: Jetpack plugin installation via proxy failed. \(error.localizedDescription)")
                self?.state = .failure(.unknown)
            }
        }

        // TODO: Handle cancellation?
    }

    func track(_ event: JetpackRemoteInstallEvent) {
        // TODO: Create a thin tracker object as dependency to make this testable.
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

    // View data overrides.
    var viewData: JetpackRemoteInstallStateViewData {
        return .init(
            state: state,
            descriptionText: (state == .success ? Constants.successDescriptionText : state.message),
            buttonTitleText: (state == .success ? Constants.successButtonTitleText : state.buttonTitle)
        )
    }

}
