/// Controls the Jetpack Remote Install flow for Jetpack-connected self-hosted sites.
///
/// A site can establish a Jetpack connection through individual Jetpack plugins, but the site may not have
/// the full Jetpack plugin. This covers the logic behind the plugin installation process, and will stop the
/// process before proceeding to the Jetpack connection step (since the site is already connected).
///
class WPComJetpackRemoteInstallViewModel {

    // The flow should complete after the plugin is installed.
    let shouldConnectToJetpack = false

    var onChangeState: ((JetpackRemoteInstallState) -> Void)? = nil

    private(set) var state: JetpackRemoteInstallState = .install {
        didSet {
            onChangeState?(state)
        }
    }

}

// MARK: - View Model Implementation

extension WPComJetpackRemoteInstallViewModel: JetpackRemoteInstallViewModel {
    func viewReady() {
        // TODO
    }

    func installJetpack(for blog: Blog, isRetry: Bool) {
        // TODO
    }

    func track(_ event: JetpackRemoteInstallEvent) {
        // TODO
    }
}

// MARK: - Jetpack State View Model Overrides

extension WPComJetpackRemoteInstallViewModel {
    var descriptionText: String {
        state == .success ? Constants.successDescriptionText : state.message
    }

    var buttonTitleText: String {
        state == .success ? Constants.successButtonTitleText : state.buttonTitle
    }
}

// MARK: - Private Helpers

private extension WPComJetpackRemoteInstallViewModel {
    enum Constants {
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
}
