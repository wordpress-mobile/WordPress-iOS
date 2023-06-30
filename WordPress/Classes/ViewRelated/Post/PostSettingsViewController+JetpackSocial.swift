
extension PostSettingsViewController {

    @objc func showNoConnection() -> Bool {
        let isJetpackSocialEnabled = FeatureFlag.jetpackSocial.enabled
        let isNoConnectionViewHidden = UserPersistentStoreFactory.instance().bool(forKey: hideNoConnectionViewKey())
        let blogSupportsPublicize = apost.blog.supportsPublicize()
        let blogHasNoConnections = publicizeConnections.count == 0
        let blogHasServices = availableServices().count > 0

        return isJetpackSocialEnabled
        && !isNoConnectionViewHidden
        && blogSupportsPublicize
        && blogHasNoConnections
        && blogHasServices
    }

    @objc func createNoConnectionView() -> UIView {
        let services = availableServices()
        let viewModel = JetpackSocialNoConnectionViewModel(services: services,
                                                           onConnectTap: onConnectTap(),
                                                           onNotNowTap: onNotNowTap())
        let viewController = JetpackSocialNoConnectionView.createHostController(with: viewModel)

        // Returning just the view means the view controller will deallocate but we don't need a
        // reference to it. The view itself holds onto the view model.
        return viewController.view
    }

    private func hideNoConnectionViewKey() -> String {
        guard let dotComID = apost.blog.dotComID?.stringValue else {
            return Constants.hideNoConnectionViewKey
        }

        return "\(dotComID)-\(Constants.hideNoConnectionViewKey)"
    }

    private func onConnectTap() -> () -> Void {
        return { [weak self] in
            guard let blog = self?.apost.blog,
                  let controller = SharingViewController(blog: blog, delegate: self) else {
                return
            }
            self?.navigationController?.pushViewController(controller, animated: true)
        }
    }

    private func onNotNowTap() -> () -> Void {
        return { [weak self] in
            guard let key = self?.hideNoConnectionViewKey() else {
                return
            }
            UserPersistentStoreFactory.instance().set(true, forKey: key)
            self?.tableView.reloadData()
        }
    }

    private func availableServices() -> [PublicizeService] {
        let context = apost.managedObjectContext ?? ContextManager.shared.mainContext
        let services = try? PublicizeService.allPublicizeServices(in: context)
        return services ?? []
    }

    // MARK: - Constants

    private struct Constants {
        static let hideNoConnectionViewKey = "post-settings-social-no-connection-view-hidden"
    }

}

// MARK: - SharingViewControllerDelegate

extension PostSettingsViewController: SharingViewControllerDelegate {

    public func didChangePublicizeServices() {
        tableView.reloadData()
    }

}
