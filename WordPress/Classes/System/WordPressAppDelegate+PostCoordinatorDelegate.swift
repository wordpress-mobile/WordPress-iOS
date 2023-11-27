import UIKit

extension WordPressAppDelegate: PostCoordinatorDelegate {
    func postCoordinator(_ postCoordinator: PostCoordinator, promptForPasswordForBlog blog: Blog) {
        showPasswordInvalidPrompt(for: blog)
    }

    func showPasswordInvalidPrompt(for blog: Blog) {
        WPError.showAlert(withTitle: Strings.unableToConnect, message: Strings.invalidPasswordMessage, withSupportButton: true) { _ in

            let editSiteViewController = SiteSettingsViewController(blog: blog)

            let navController = UINavigationController(rootViewController: editSiteViewController!)

            editSiteViewController?.navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .done, primaryAction: UIAction { [weak navController] _ in
                navController?.presentingViewController?.dismiss(animated: true)
            })

            self.window?.topmostPresentedViewController?.present(navController, animated: true)
        }
    }
}

private enum Strings {
    static let invalidPasswordMessage = NSLocalizedString("common.reEnterPasswordMessage", value: "The username or password stored in the app may be out of date. Please re-enter your password in the settings and try again.", comment: "Error message informing a user about an invalid password.")
    static let unableToConnect = NSLocalizedString("common.unableToConnect", value: "Unable to Connect", comment: "An error message.")
}
