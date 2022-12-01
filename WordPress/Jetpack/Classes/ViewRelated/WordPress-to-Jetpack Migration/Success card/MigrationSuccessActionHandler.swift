import UIKit

@objcMembers final class MigrationSuccessActionHandler {

    func showDeleteWordPressOverlay(with viewController: UIViewController) {
        let destination = MigrationDeleteWordPressViewController()
        viewController.present(UINavigationController(rootViewController: destination), animated: true)
    }
}
