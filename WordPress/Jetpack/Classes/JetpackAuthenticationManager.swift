import WordPressAuthenticator

struct JetpackAuthenticationManager: AuthenticationHandler {
    var statusBarStyle: UIStatusBarStyle = .lightContent
    var prologueViewController: UIViewController? = JetpackPrologueViewController()
    var buttonViewTopShadowImage: UIImage? = UIImage()
    var prologueButtonsBackgroundColor: UIColor? = JetpackPrologueStyleGuide.backgroundColor

    var prologuePrimaryButtonStyle: NUXButtonStyle? = JetpackPrologueStyleGuide.continueButtonStyle
    var prologueSecondaryButtonStyle: NUXButtonStyle? = JetpackPrologueStyleGuide.siteAddressButtonStyle

    func willHandlePresentLoginEpilogue(in navigationController: UINavigationController, for credentials: AuthenticatorCredentials) -> Bool {
        // Don't display the "no sites" epilogue if we allow site creation
        return !AppConfiguration.allowSiteCreation
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

    func willHandlePresentSignupEpilogue(in navigationController: UINavigationController, for credentials: AuthenticatorCredentials, service: SocialService?) -> Bool {
        // Don't display the "no sites" epilogue if we allow site creation
        return !AppConfiguration.allowSiteCreation
    }

    // If the user signs up using the Jetpack app (through SIWA, for example)
    // We show right away the screen explaining that they do not have Jetpack sites
    func presentSignupEpilogue(in navigationController: UINavigationController, for credentials: AuthenticatorCredentials, service: SocialService?) {
        let windowManager = WordPressAppDelegate.shared?.windowManager

        windowManager?.dismissFullscreenSignIn()

        let viewModel = JetpackNoSitesErrorViewModel()
        let controller = errorViewController(with: viewModel)
        windowManager?.show(controller, completion: nil)
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
