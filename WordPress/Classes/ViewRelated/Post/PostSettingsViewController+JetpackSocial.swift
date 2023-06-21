
extension PostSettingsViewController {

    @objc func showNoConnection() -> Bool {
        let isJetpackSocialEnabled = FeatureFlag.jetpackSocial.enabled
        let blogSupportsPublicize = apost.blog.supportsPublicize()
        let blogHasNoConnections = publicizeConnections.count == 0
        return isJetpackSocialEnabled && blogSupportsPublicize && blogHasNoConnections
    }

    @objc func createNoConnectionView() -> UIView {
        let viewModel = JetpackSocialNoConnectionViewModel(
            onConnectTap: {
                // TODO: Open the social screen
                print("Connect tap")
            }, onNotNowTap: {
                // TODO: Add condition to hide the connection view after not now is tapped
                print("Not now tap")
            }
        )
        let viewController = JetpackSocialNoConnectionView.createHostController(with: viewModel)

        // Returning just the view means the view controller will deallocate but we don't need a
        // reference to it. The view itself holds onto the view model.
        return viewController.view
    }

}
