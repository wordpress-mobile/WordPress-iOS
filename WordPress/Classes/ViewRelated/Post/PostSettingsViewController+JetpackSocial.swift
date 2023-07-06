import SwiftUI

extension PostSettingsViewController {

    // MARK: - No connection view

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

    // MARK: - Remaining shares view

    @objc func showRemainingShares() -> Bool {
        let isJetpackSocialEnabled = FeatureFlag.jetpackSocial.enabled
        let blogSupportsPublicize = apost.blog.supportsPublicize()
        let blogHasConnections = publicizeConnections.count > 0
        let isSocialSharingLimited = apost.blog.isSocialSharingLimited
        let blogHasPublicizeInfo = apost.blog.publicizeInfo != nil

        return isJetpackSocialEnabled
        && blogSupportsPublicize
        && blogHasConnections
        && isSocialSharingLimited
        && blogHasPublicizeInfo
    }



    @objc func createRemainingSharesView() -> UIView {
        guard let sharingLimit = apost.blog.sharingLimit else {
            // This scenario *shouldn't* happen since we check that the publicize info is not nil before
            // showing this view
            assertionFailure("No sharing limit on the blog")
            return UIView()
        }

        let shouldDisplayWarning = publicizeConnections.count > sharingLimit.remaining
        let viewModel = JetpackSocialRemainingSharesViewModel(remaining: sharingLimit.remaining,
                                                              limit: sharingLimit.limit,
                                                              displayWarning: shouldDisplayWarning,
                                                              onSubscribeTap: onSubscribeTap())
        let hostController = UIHostingController(rootView: JetpackSocialSettingsRemainingSharesView(viewModel: viewModel))
        hostController.view.translatesAutoresizingMaskIntoConstraints = false
        hostController.view.backgroundColor = .listForeground
        return hostController.view
    }

}

// MARK: - Private methods

private extension PostSettingsViewController {

    func hideNoConnectionViewKey() -> String {
        guard let dotComID = apost.blog.dotComID?.stringValue else {
            return Constants.hideNoConnectionViewKey
        }

        return "\(dotComID)-\(Constants.hideNoConnectionViewKey)"
    }

    func onConnectTap() -> () -> Void {
        return { [weak self] in
            guard let blog = self?.apost.blog,
                  let controller = SharingViewController(blog: blog, delegate: nil) else {
                return
            }
            self?.navigationController?.pushViewController(controller, animated: true)
        }
    }

    func onNotNowTap() -> () -> Void {
        return { [weak self] in
            guard let key = self?.hideNoConnectionViewKey() else {
                return
            }
            UserPersistentStoreFactory.instance().set(true, forKey: key)
            self?.tableView.reloadData()
        }
    }

    func onSubscribeTap() -> () -> Void {
        return { [weak self] in
            guard let blog = self?.apost.blog,
                  let hostname = blog.hostname,
                  let url = URL(string: "https://wordpress.com/checkout/\(hostname)/jetpack_social_basic_yearly") else {
                return
            }
            let webViewController = WebViewControllerFactory.controller(url: url,
                                                                        blog: blog,
                                                                        source: "post_settings_remaining_shares_subscribe_now")
            let navigationController = UINavigationController(rootViewController: webViewController)
            self?.present(navigationController, animated: true)
        }
    }

    func availableServices() -> [PublicizeService] {
        let context = apost.managedObjectContext ?? ContextManager.shared.mainContext
        let services = try? PublicizeService.allPublicizeServices(in: context)
        return services ?? []
    }

    // MARK: - Constants

    struct Constants {
        static let hideNoConnectionViewKey = "post-settings-social-no-connection-view-hidden"
    }

}
