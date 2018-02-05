import Foundation

extension NotificationsViewController {

    func promptForJetpackCredentials() {
        guard !showingJetpackLogin,
            let blog = blogService.lastUsedBlog() else {
            return
        }

        showingJetpackLogin = true
        let controller = JetpackLoginViewController(blog: blog)
        controller.presenter = .notifications
        controller.completionBlock = { [weak self, weak controller] in
            self?.activityIndicator.stopAnimating()
            self?.blogService.syncBlog(blog, success: {
                self?.activityIndicator.stopAnimating()
                if blog.account != nil {
                    WPAppAnalytics.track(.signedInToJetpack, with: blog)
                    WPAppAnalytics.track(.performedJetpackSignInFromNotificationsScreen, with: blog)
                    controller?.view.removeFromSuperview()
                    controller?.removeFromParentViewController()
                    self?.showingJetpackLogin = false
                    self?.tableView.reloadData()
                } else {
                    controller?.updateMessage()
                }
            }, failure: { (error) in
                self?.activityIndicator.stopAnimating()
                DDLogError("Error syncing blog for Jetpack status from Notifications \(error)")
            })
        }
        addChildViewController(controller)
        tableView.addSubview(withFadeAnimation: controller.view)
        controller.view.center = tableView.center
    }


    // MARK: - Private Computed Properties

    fileprivate var blogService: BlogService {
        return BlogService(managedObjectContext: managedObjectContext())
    }

}
