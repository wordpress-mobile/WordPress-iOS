import UIKit

extension MySiteViewController {
    func subscribeToJetpackInstallNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(launchJetpackInstallFromNotification(_:)), name: .installJetpack, object: nil)
    }

    /// Presents the Jetpack Login (Install) controller from a notification
    @objc func launchJetpackInstallFromNotification(_ notification: NSNotification) {
        guard let blog = blog else {
            return
        }

        let controller = JetpackLoginViewController(blog: blog)
        controller.promptType = .installPrompt

        let navController = UINavigationController(rootViewController: controller)
        navController.modalPresentationStyle = .fullScreen

        navigationController?.present(navController, animated: true)

        controller.completionBlock = { [weak self] in
            defer {
                navController.dismiss(animated: true)
            }

            guard let self = self else {
                return
            }

            DispatchQueue.main.async {
                self.syncBlogs()
            }
        }
    }
}
