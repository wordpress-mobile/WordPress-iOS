import Foundation


extension UIAlertController {
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
    
    func presentAlertForCopy(_ text: String?, completion: ((Notice) -> Void)? = nil) {
        guard let text = text else {
            completion?(failureNotice)
            return
        }
        self.addDefaultActionWithTitle(NSLocalizedString("Copy", comment: "Copy button")) { [weak self] alertAction in
            guard let strongSelf = self else {
                assertionFailure("UIAlertController was nil when trying to set action in presentAlertForCopy")
                return
            }
            UIPasteboard.general.string = text
            completion?(strongSelf.successNotice)
        }
        
        self.addCancelActionWithTitle(NSLocalizedString("Cancel", comment: "Cancel button"))
        presentFromRootViewController()
    }
    
    private var successNotice: Notice {
        let title = NSLocalizedString("Link Copied to Clipboard", comment: "")
        return Notice(title: title)
    }
    
    private var failureNotice: Notice {
        let title = NSLocalizedString("Copy to Clipboard failed", comment: "")
        return Notice(title: title)
    }
}
