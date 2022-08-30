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
        let navigationController = UINavigationController(rootViewController: installPromptViewController)
        navigationController.modalPresentationStyle = .fullScreen

        installPromptViewController.dismiss = { [weak self] dismissAction in
            promptSettings.setPromptWasDismissed(true, for: blog)

            switch dismissAction {
            case .install:
                self?.syncBlogs()
            default:
                break
            }
        }

        present(navigationController, animated: true)
    }
}
