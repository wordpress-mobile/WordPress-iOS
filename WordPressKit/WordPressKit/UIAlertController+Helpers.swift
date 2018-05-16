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
}
