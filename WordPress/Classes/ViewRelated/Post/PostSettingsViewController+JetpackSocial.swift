import SwiftUI
import AutomatticTracks

extension PostSettingsViewController {

    // MARK: - No connection view

    @objc func showNoConnection() -> Bool {
        let isJetpackSocialEnabled = RemoteFeatureFlag.jetpackSocialImprovements.enabled()
        let isNoConnectionViewHidden = UserPersistentStoreFactory.instance().bool(forKey: hideNoConnectionViewKey())
        let blogSupportsPublicize = apost.blog.supportsPublicize()
        let blogHasNoConnections = publicizeConnections.count == 0 && unsupportedConnections.count == 0
        let blogHasServices = availableServices().count > 0

        return isJetpackSocialEnabled
        && !isNoConnectionViewHidden
        && blogSupportsPublicize
        && blogHasNoConnections
        && blogHasServices
        && !isPostPrivate
    }

    @objc func createNoConnectionView() -> UIView {
        WPAnalytics.track(.jetpackSocialNoConnectionCardDisplayed,
                          properties: ["source": Constants.trackingSource])
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
        let isJetpackSocialEnabled = RemoteFeatureFlag.jetpackSocialImprovements.enabled()
        let blogSupportsPublicize = apost.blog.supportsPublicize()
        let blogHasConnections = publicizeConnections.count > 0
        let blogHasSharingLimit = apost.blog.sharingLimit != nil

        return isJetpackSocialEnabled
        && blogSupportsPublicize
        && blogHasConnections
        && blogHasSharingLimit
        && !isPostPrivate
    }

    @objc func createRemainingSharesView() -> UIView {
        guard let sharingLimit = apost.blog.sharingLimit else {
            // This scenario *shouldn't* happen since we check that the publicize info is not nil before
            // showing this view
            assertionFailure("No sharing limit on the blog")
            let error = JetpackSocialError.missingSharingLimit
            CrashLogging.main.logError(error, userInfo: ["source": "post_settings"])
            return UIView()
        }
        WPAnalytics.track(.jetpackSocialShareLimitDisplayed,
                          properties: ["source": Constants.trackingSource])

        let shouldDisplayWarning = publicizeConnections.count > sharingLimit.remaining
        let viewModel = JetpackSocialRemainingSharesViewModel(remaining: sharingLimit.remaining,
                                                              displayWarning: shouldDisplayWarning,
                                                              onSubscribeTap: onSubscribeTap())
        let hostController = UIHostingController(rootView: JetpackSocialSettingsRemainingSharesView(viewModel: viewModel))
        hostController.view.translatesAutoresizingMaskIntoConstraints = false
        hostController.view.backgroundColor = .secondarySystemGroupedBackground
        return hostController.view
    }

    // MARK: - Social share cells

    @objc func userCanEditSharing() -> Bool {
        guard let post = self.apost as? Post else {
            return false
        }
        guard RemoteFeatureFlag.jetpackSocialImprovements.enabled() else {
            return post.canEditPublicizeSettings()
        }

        return post.canEditPublicizeSettings() && remainingSocialShares() > 0
    }

    @objc func remainingSocialShares() -> Int {
        self.apost.blog.sharingLimit?.remaining ?? .max
    }

}

// MARK: - Private methods

private extension PostSettingsViewController {

    var isPostPrivate: Bool {
        apost.status == .publishPrivate
    }

    func hideNoConnectionViewKey() -> String {
        guard let dotComID = apost.blog.dotComID?.stringValue else {
            return Constants.hideNoConnectionViewKey
        }

        return "\(dotComID)-\(Constants.hideNoConnectionViewKey)"
    }

    func onConnectTap() -> () -> Void {
        return { [weak self] in
            WPAnalytics.track(.jetpackSocialNoConnectionCTATapped,
                              properties: ["source": Constants.trackingSource])
            guard let blog = self?.apost.blog,
                  let controller = SharingViewController(blog: blog, delegate: nil) else {
                return
            }
            self?.navigationController?.pushViewController(controller, animated: true)
        }
    }

    func onNotNowTap() -> () -> Void {
        return { [weak self] in
            WPAnalytics.track(.jetpackSocialNoConnectionCardDismissed,
                              properties: ["source": Constants.trackingSource])
            guard let key = self?.hideNoConnectionViewKey() else {
                return
            }
            UserPersistentStoreFactory.instance().set(true, forKey: key)
            self?.tableView.reloadData()
        }
    }

    func onSubscribeTap() -> () -> Void {
        return { [weak self] in
            WPAnalytics.track(.jetpackSocialUpgradeLinkTapped,
                              properties: ["source": Constants.trackingSource])
            guard let blog = self?.apost.blog,
                  let hostname = blog.hostname,
                  let url = URL(string: "https://wordpress.com/checkout/\(hostname)/jetpack_social_basic_yearly") else {
                return
            }
            let webViewController = WebViewControllerFactory.controller(url: url,
                                                                        blog: blog,
                                                                        source: "post_settings_remaining_shares_subscribe_now") {
                self?.checkoutDismissed()
            }
            let navigationController = UINavigationController(rootViewController: webViewController)
            self?.present(navigationController, animated: true)
        }
    }

    func checkoutDismissed() {
        let coreDataStack = ContextManager.shared
        let service = BlogService(coreDataStack: coreDataStack)
        service.syncBlog(apost.blog) { [weak self] in
            let sharingLimit: PublicizeInfo.SharingLimit? = coreDataStack.performQuery { context in
                guard let dotComID = self?.apost.blog.dotComID,
                      let blog = Blog.lookup(withID: dotComID, in: context) else {
                    return nil
                }
                return blog.sharingLimit
            }
            if sharingLimit == nil {
                self?.reloadData()
            }
        } failure: { error in
            DDLogError("Failed to sync blog after dismissing checkout webview due to error: \(error)")
        }
    }

    func availableServices() -> [PublicizeService] {
        let context = apost.managedObjectContext ?? ContextManager.shared.mainContext
        let services = try? PublicizeService.allSupportedServices(in: context)
        return services ?? []
    }

    // MARK: - Constants

    struct Constants {
        static let hideNoConnectionViewKey = "post-settings-social-no-connection-view-hidden"
        static let trackingSource = "post_settings"
    }

}
