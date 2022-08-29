import UIKit

extension MySiteViewController {
    func subscribeToJetpackInstallNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(promptJetpackPluginInstallFromNotification(_:)), name: .promptInstallJetpack, object: nil)
    }

    /// Presents the prompt to install Jetpack from a notification
    @objc func promptJetpackPluginInstallFromNotification(_ notification: NSNotification) {
        guard let blog = blog,
            let promptSettings = notification.userInfo?["jetpackInstallPromptSettings"] as? JetpackInstallPromptSettings else {
            return
        }

        let installPromptViewController = JetpackInstallPromptViewController(blog: blog)
        let installPromptNavigationController = UINavigationController(rootViewController: installPromptViewController)
        installPromptNavigationController.modalPresentationStyle = .fullScreen

        installPromptViewController.actionHandler = { [weak self] action in
            switch action {
            case .noThanks:
                installPromptNavigationController.dismiss(animated: true)
            case .install:
                self?.presentJetpackInstall(on: installPromptNavigationController, blog: blog, jetpackInstallPromptSettings: promptSettings)
            }
        }

        present(installPromptNavigationController, animated: true)
    }

    /// Presents the Jetpack plugin install flow on top of the prompt
    private func presentJetpackInstall(
        on controller: UINavigationController,
        blog: Blog,
        jetpackInstallPromptSettings: JetpackInstallPromptSettings
    ) {
        let jetpackLoginViewController = JetpackLoginViewController(blog: blog)
        jetpackLoginViewController.promptType = .installPrompt
        let navigationController = UINavigationController(rootViewController: jetpackLoginViewController)
        navigationController.modalPresentationStyle = .fullScreen

        controller.present(navigationController, animated: true)

        jetpackLoginViewController.completionBlock = { [weak self] in
            jetpackInstallPromptSettings.setPromptWasDismissed(true, for: blog)

            /// If Jetpack install + WP.com login flow is completed, the blog will be synced and jetpack.isConnected will be true
            /// Dismissing the prompt
            if let jetpack = blog.jetpack, jetpack.isConnected {
                self?.syncBlogs()
                controller.dismiss(animated: true)

            /// If Jetpack install + WP.com login flow was not fully completed, the blog will not be synced
            /// Jetpack.isConnected can still be true if the flow is completed except for WP.com login
            /// Sync the blog and dismiss the prompt if Jetpack.isConnected
            } else {
                let blogService = BlogService(managedObjectContext: ContextManager.shared.mainContext)
                blogService.syncBlog(blog) {
                    if let jetpack = blog.jetpack, jetpack.isConnected {
                        controller.dismiss(animated: true)
                    }
                } failure: { _ in
                    controller.dismiss(animated: true)
                }
            }
        }
    }
}
