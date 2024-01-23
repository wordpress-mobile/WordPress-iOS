extension NotificationsViewController {

    var blogForJetpackPrompt: Blog? {
        return Blog.lastUsed(in: managedObjectContext())
    }

    func promptForJetpackCredentials() {
        guard let blog = blogForJetpackPrompt else {
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
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                controller.view.topAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.topAnchor),
                controller.view.leadingAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.leadingAnchor),
                controller.view.trailingAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.trailingAnchor),
                controller.view.bottomAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.bottomAnchor)
            ])
            configureControllerCompletion(controller, withBlog: blog)
            jetpackLoginViewController = controller
            controller.didMove(toParent: self)
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
                self?.configureJetpackBanner()
                self?.tableView.reloadData()
            } else {
                self?.activityIndicator.stopAnimating()
                controller?.updateMessageAndButton()
            }
        }
    }

}
