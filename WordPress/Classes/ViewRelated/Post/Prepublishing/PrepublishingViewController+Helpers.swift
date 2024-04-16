import UIKit

extension PrepublishingViewController {
    static func show(for revision: AbstractPost, action: PostEditorAction, isStandalone: Bool = false, from presentingViewController: UIViewController, completion: @escaping (PrepublishingSheetResult) -> Void) {
        guard RemoteFeatureFlag.syncPublishing.enabled() else {
            return _show(for: revision, action: action, from: presentingViewController, completion: completion)
        }
        show(post: revision, isStandalone: isStandalone, from: presentingViewController, completion: completion)
    }

    /// - warning: deprecated (kahu-offline-mode)
    private static func _show(for revision: AbstractPost, action: PostEditorAction, from presentingViewController: UIViewController, completion: @escaping (PrepublishingSheetResult) -> Void) {
        switch revision {
        case let post as Post:
            showDeprecated(post: post, from: presentingViewController, completion: completion)
        case let page as Page:
            showAlert(for: page, action: action, from: presentingViewController, completion: completion)
        default:
            wpAssertionFailure("Unsupported post type")
            break
        }
    }

    private static func show(post: AbstractPost, isStandalone: Bool, from presentingViewController: UIViewController, completion: @escaping (PrepublishingSheetResult) -> Void) {
        // End editing to avoid issues with accessibility
        presentingViewController.view.endEditing(true)

        let viewController = PrepublishingViewController(post: post, isStandalone: isStandalone, completion: completion)
        viewController.presentAsSheet(from: presentingViewController)
    }

    private static func showDeprecated(post: Post, from presentingViewController: UIViewController, completion: @escaping (PrepublishingSheetResult) -> Void) {
        // End editing to avoid issues with accessibility
        presentingViewController.view.endEditing(true)

        let viewController = DeprecatedPrepublishingViewController(post: post, identifiers: PrepublishingIdentifier.defaultIdentifiers, completion: completion)
        viewController.presentAsSheet(from: presentingViewController)
    }

    private static func showAlert(for page: Page, action: PostEditorAction, from presentingViewController: UIViewController, completion: @escaping (PrepublishingSheetResult) -> Void) {
        let title = action.publishingActionQuestionLabel
        let keepEditingTitle = NSLocalizedString("Keep Editing", comment: "Button shown when the author is asked for publishing confirmation.")
        let publishTitle = action.publishActionLabel
        let style: UIAlertController.Style = UIDevice.isPad() ? .alert : .actionSheet
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: style)

        alertController.addCancelActionWithTitle(keepEditingTitle) { _ in
            completion(.cancelled)
        }
        alertController.addDefaultActionWithTitle(publishTitle) { _ in
            completion(.confirmed)
        }
        presentingViewController.present(alertController, animated: true, completion: nil)
    }
}
