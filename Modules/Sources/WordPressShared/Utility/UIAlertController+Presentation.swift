import UIKit

@objc public extension UIAlertController {
    // FIXME: Given we use the custom leafViewController, this should be called presentFromLeafViewController
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
