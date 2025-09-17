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

        let publishVC = PublishPostViewController(post: revision)
        publishVC.onCompletion = completion
        publishVC.sheetPresentationController?.detents = [.medium(), .large()]
        presentingViewController.present(publishVC, animated: true)
    }
}
