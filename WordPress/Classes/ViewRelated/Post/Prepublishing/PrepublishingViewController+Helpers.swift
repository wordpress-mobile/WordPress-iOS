import UIKit
import WordPressData

extension PrepublishingViewController {
    static func show(for revision: AbstractPost, isStandalone: Bool = false, from presentingViewController: UIViewController, completion: @escaping (PrepublishingSheetResult) -> Void) {
        // End editing to avoid issues with accessibility
        presentingViewController.view.endEditing(true)

        guard FeatureFlag.newPublishingSheet.enabled else {
            let viewController = PrepublishingViewController(post: revision, isStandalone: isStandalone, completion: completion)
            viewController.presentAsSheet(from: presentingViewController)
            return
        }

        let publishVC = PublishPostViewController(post: revision, isStandalone: isStandalone)
        publishVC.onCompletion = completion
        // - warning: Has to be UIKit because some of the  `PostSettingsView` rows rely on it.
        let navigationVC = UINavigationController(rootViewController: publishVC)
        navigationVC.sheetPresentationController?.detents = [
            .custom(identifier: .medium, resolver: { context in 526 }),
            .large()
        ]
        presentingViewController.present(navigationVC, animated: true)
    }
}
