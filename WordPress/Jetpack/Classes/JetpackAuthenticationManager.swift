import WordPressAuthenticator

struct JetpackAuthenticationManager: AuthenticationHandler {
    var statusBarStyle: UIStatusBarStyle = .lightContent
    var prologueViewController: UIViewController? = JetpackPrologueViewController()
    var buttonViewTopShadowImage: UIImage? = UIImage()
    var prologueButtonsBackgroundColor: UIColor? = JetpackPrologueStyleGuide.backgroundColor

    var prologuePrimaryButtonStyle: NUXButtonStyle? = JetpackPrologueStyleGuide.continueButtonStyle
    var prologueSecondaryButtonStyle: NUXButtonStyle? = JetpackPrologueStyleGuide.siteAddressButtonStyle

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
