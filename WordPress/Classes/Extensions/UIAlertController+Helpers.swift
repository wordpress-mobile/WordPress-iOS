import Foundation
import WordPressFlux

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
}

//MARK: - copy text to Clipboard
extension UIAlertController {
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

    /// This method is will present an alert controller (action sheet style) that
    /// provides a copy action to allow copying the text parameter to the clip board.
    /// Once copied, or on failure to copy, a notice will be posted using the dispacher so the user will know
    /// if copying to clipboard was successful
    @objc static func presentAlertAndCopyTextToClipboard(text: String?) {
        let successNoticeTitle = NSLocalizedString("Link Copied to Clipboard", comment: "Successful copy notice title")
        let failureNoticeTitle = NSLocalizedString("Copy to Clipboard failed", comment: "Failed to copy notice title")
        let copyAlertController = UIAlertController.copyTextAlertController(text) { success in
            let title = success ? successNoticeTitle : failureNoticeTitle
            ActionDispatcher.dispatch(NoticeAction.post(Notice(title: title)))
        }
        copyAlertController?.presentFromRootViewController()
    }
}
