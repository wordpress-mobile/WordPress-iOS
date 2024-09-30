import UIKit

extension PrepublishingViewController {
    static func show(for revision: AbstractPost, isStandalone: Bool = false, from presentingViewController: UIViewController, completion: @escaping (PrepublishingSheetResult) -> Void) {
        // End editing to avoid issues with accessibility
        presentingViewController.view.endEditing(true)

        let viewController = PrepublishingViewController(post: revision, isStandalone: isStandalone, completion: completion)
        viewController.presentAsSheet(from: presentingViewController)
    }
}
