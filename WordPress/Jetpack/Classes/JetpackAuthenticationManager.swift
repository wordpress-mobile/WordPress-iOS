import WordPressAuthenticator

struct JetpackAuthenticationManager: AuthenticationHandler {
    func shouldPresentUsernamePasswordController(for siteInfo: WordPressComSiteInfo?, onCompletion: @escaping (WordPressAuthenticatorResult) -> Void) {
        /// Jetpack is required. Present an error if we don't detect a valid installation.
        guard let site = siteInfo, isValidJetpack(for: site) else {
            let viewModel = JetpackErrorViewModel(title: "Jetpack Not Found")
            let controller = errorViewController(with: viewModel)

            let authenticationResult: WordPressAuthenticatorResult = .injectViewController(value: controller)
            onCompletion(authenticationResult)

            return
        }

        /// WordPress must be present.
        guard site.isWP else {
            let viewModel = JetpackErrorViewModel(title: "WordPress Not Installed")
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

    func presentLoginEpilogue(in navigationController: UINavigationController, for credentials: AuthenticatorCredentials, onDismiss: @escaping () -> Void) -> Bool {
        if hasJetpackSites() {
            return false
        }

        let viewModel = JetpackErrorViewModel(title: "No Jetpack Sites")
        let controller = errorViewController(with: viewModel)
        navigationController.pushViewController(controller, animated: true)

        return true
    }

    // MARK: - Private: Helpers
    private func isValidJetpack(for site: WordPressComSiteInfo) -> Bool {
        return site.hasJetpack &&
            site.isJetpackConnected &&
            site.isJetpackActive
    }

    private func hasJetpackSites() -> Bool {
        let context = ContextManager.sharedInstance().mainContext
        let blogService = BlogService(managedObjectContext: context)

        return blogService.blogCountForAllAccounts() > 0
    }

    private func errorViewController(with model: JetpackErrorViewModel) -> JetpackLoginErrorViewController {
        return JetpackLoginErrorViewController(viewModel: model)
    }
}
