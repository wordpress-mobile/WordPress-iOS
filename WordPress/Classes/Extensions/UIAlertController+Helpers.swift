import Foundation


@objc extension UIAlertController {
    @objc func presentFromRootViewController() {
        // Note:
        // This method is required because the presenter ViewController must be visible, and we've got several
        // flows in which the VC that triggers the alert, might not be visible anymore.
        //
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
            print("Error loading the rootViewController")
            return
        }

        var leafViewController = rootViewController
        while leafViewController.presentedViewController != nil && !leafViewController.presentedViewController!.isBeingDismissed {
            leafViewController = leafViewController.presentedViewController!
        }
        leafViewController.present(self, animated: true, completion: nil)
    }

    /// This method is used for presenting the Action sheet
    /// for copying text to clipboard. The action sheet has 2 options:
    /// copy: will copy the text to the clipboard
    /// cancel: dismiss the action sheet
    @objc static func copyTextAlertController(_ text: String?,
                                              completion: ((Bool) -> Void)? = nil) -> UIAlertController? {
        guard let text = text else {
            completion?(false)
            return nil
        }
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addDefaultActionWithTitle(NSLocalizedString("Copy", comment: "Copy button")) { _ in
            UIPasteboard.general.string = text
            completion?(true)
        }
        alertController.addCancelActionWithTitle(NSLocalizedString("Cancel", comment: "Cancel button"))
        return alertController
    }
}
