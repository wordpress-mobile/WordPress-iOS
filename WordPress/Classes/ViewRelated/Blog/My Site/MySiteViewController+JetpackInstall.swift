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

        let installPromptViewController = JetpackInstallPromptViewController(blog: blog, promptSettings: promptSettings, delegate: self)
        let navigationController = UINavigationController(rootViewController: installPromptViewController)
        navigationController.modalPresentationStyle = .fullScreen

        present(navigationController, animated: true)
    }
}

extension MySiteViewController: JetpackInstallPromptDelegate {
    func jetpackInstallPromptDidDismiss(_ action: JetpackInstallPromptDismissAction) {
        switch action {
        case .install:
            self.syncBlogs()
        default:
            break
        }
    }
}
