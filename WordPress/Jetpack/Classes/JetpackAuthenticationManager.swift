import WordPressAuthenticator

struct JetpackAuthenticationManager: AuthenticationHandler {
    var statusBarStyle: UIStatusBarStyle = .lightContent
    var prologueViewController: UIViewController? = JetpackPrologueViewController()
    var buttonViewTopShadowImage: UIImage? = UIImage()
    var prologueButtonsBackgroundColor: UIColor? = JetpackPrologueStyleGuide.backgroundColor

    var prologuePrimaryButtonStyle: NUXButtonStyle? = JetpackPrologueStyleGuide.continueButtonStyle
    var prologueSecondaryButtonStyle: NUXButtonStyle? = JetpackPrologueStyleGuide.siteAddressButtonStyle

    func shouldPresentUsernamePasswordController(for siteInfo: WordPressComSiteInfo?, onCompletion: @escaping (WordPressAuthenticatorResult) -> Void) {
        /// Jetpack is required. Present an error if we don't detect a valid installation.
        guard let site = siteInfo, isValidJetpack(for: site) else {
            let viewModel = JetpackNotFoundErrorViewModel(with: siteInfo?.url)
            let controller = errorViewController(with: viewModel)

            let authenticationResult: WordPressAuthenticatorResult = .injectViewController(value: controller)
            onCompletion(authenticationResult)

            return
        }

        /// WordPress must be present.
        guard site.isWP else {
            let viewModel = JetpackNotWPErrorViewModel()
            let controller = errorViewController(with: viewModel)

            let authenticationResult: WordPressAuthenticatorResult = .injectViewController(value: controller)
            onCompletion(authenticationResult)

            return
        }

        /// For self-hosted sites, navigate to enter the email address associated to the wp.com account:
        guard site.isWPCom else {
            let authenticationResult: WordPressAuthenticatorResult = .presentEmailController

            onCompletion(authenticationResult)

            return
        }

        /// We should never reach this point, as WPAuthenticator won't call its delegate for this case.
        ///
        DDLogWarn("⚠️ Present password controller for site: \(site.url)")
        let authenticationResult: WordPressAuthenticatorResult = .presentPasswordController(value: false)
        onCompletion(authenticationResult)
    }

    func presentLoginEpilogue(in navigationController: UINavigationController, for credentials: AuthenticatorCredentials, windowManager: WindowManager, onDismiss: @escaping () -> Void) -> Bool {
        if AccountHelper.hasBlogs {
            return false
        }

        // Exit out of the sign in process, if we don't do this we later can't
        // display the sign in again
        windowManager.dismissFullscreenSignIn()

        // Display the no sites view
        let viewModel = JetpackNoSitesErrorViewModel()
        let controller = errorViewController(with: viewModel)
        windowManager.show(controller, completion: nil)

        return true
    }

    // MARK: - Private: Helpers
    private func isValidJetpack(for site: WordPressComSiteInfo) -> Bool {
        return site.hasJetpack &&
            site.isJetpackConnected &&
            site.isJetpackActive
    }

    private func errorViewController(with model: JetpackErrorViewModel) -> JetpackLoginErrorViewController {
        return JetpackLoginErrorViewController(viewModel: model)
    }
}
