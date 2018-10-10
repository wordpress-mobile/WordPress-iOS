extension NotificationsViewController {

    func promptForJetpackCredentials() {
        guard let blog = blogService.lastUsedBlog() else {
            return
        }

        if let controller = jetpackLoginViewController {
            controller.blog = blog
            controller.updateMessageAndButton()
            configureControllerCompletion(controller, withBlog: blog)
        } else {
            let controller = JetpackLoginViewController(blog: blog)
            controller.promptType = .notifications
            addChild(controller)
            tableView.addSubview(withFadeAnimation: controller.view)
            controller.view.frame = CGRect(origin: .zero, size: view.frame.size)
            configureControllerCompletion(controller, withBlog: blog)
            jetpackLoginViewController = controller
        }
    }


    fileprivate func configureControllerCompletion(_ controller: JetpackLoginViewController, withBlog blog: Blog) {
        controller.completionBlock = { [weak self, weak controller] in
            if AccountHelper.isDotcomAvailable() {
                self?.activityIndicator.stopAnimating()
                WPAppAnalytics.track(.signedInToJetpack, withProperties: ["source": "notifications"], with: blog)
                controller?.view.removeFromSuperview()
                controller?.removeFromParent()
                self?.jetpackLoginViewController = nil
                self?.tableView.reloadData()
            } else {
                self?.activityIndicator.stopAnimating()
                controller?.updateMessageAndButton()
            }
        }
    }


    // MARK: - Private Computed Properties

    fileprivate var blogService: BlogService {
        return BlogService(managedObjectContext: managedObjectContext())
    }

}
