import Foundation
import WordPressFlux

@objc extension UIAlertController {
    @objc func presentFromRootViewController() {
        // Note:
        // This method is required because the presenter ViewController must be visible, and we've got several
        // flows in which the VC that triggers the alert, might not be visible anymore.
        //
        guard let leafViewController = UIApplication.shared.leafViewController else {
            return
        }
        popoverPresentationController?.sourceView = view
        popoverPresentationController?.permittedArrowDirections = []
        leafViewController.present(self, animated: true)
    }
}

// MARK: - copy comment URL to Clipboard

extension UIAlertController {
    /// This method is used for presenting the Action sheet
    /// for copying comment URL to clipboard. The action sheet has 2 options:
    /// Copy Link to Comment: will copy the text to the clipboard
    /// cancel: dismiss the action sheet
    @objc static func copyCommentURLAlertController(_ url: URL,
                                              completion: (() -> Void)? = nil) -> UIAlertController? {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addDefaultActionWithTitle(NSLocalizedString("Copy Link to Comment", comment: "Copy link to oomment button title")) { _ in
            UIPasteboard.general.url = url
            completion?()
        }
        alertController.addCancelActionWithTitle(NSLocalizedString("Cancel", comment: "Cancel copying link to comment button title"))
        return alertController
    }
}
