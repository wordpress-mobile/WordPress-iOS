
extension PostSettingsViewController {

    @objc func showNoConnection() -> Bool {
        let isJetpackSocialEnabled = FeatureFlag.jetpackSocial.enabled
        let blogSupportsPublicize = apost.blog.supportsPublicize()
        let blogHasNoConnections = publicizeConnections.count == 0
        let blogHasServices = availableServices().count > 0

        return isJetpackSocialEnabled
        && blogSupportsPublicize
        && blogHasNoConnections
        && blogHasServices
    }

    @objc func createNoConnectionView() -> UIView {
        let services = availableServices()
        let viewModel = JetpackSocialNoConnectionViewModel(
            services: services,
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

    private func availableServices() -> [PublicizeService] {
        let context = apost.managedObjectContext ?? ContextManager.shared.mainContext
        let services = try? PublicizeService.allPublicizeServices(in: context)
        return  services ?? []
    }

}
