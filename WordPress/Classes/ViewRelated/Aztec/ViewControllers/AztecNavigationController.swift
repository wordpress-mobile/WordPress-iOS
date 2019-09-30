import Foundation
import UIKit


// MARK: - AztecNavigationControllerDelegate Protocol
//
protocol AztecNavigationControllerDelegate: UINavigationControllerDelegate {

    /// This method is called whenever an instance of `UIAlertController` (was presented modally) and gets dismissed.
    ///
    func navigationController(_ navigationController: UINavigationController, didDismiss alertController: UIAlertController)
}


// MARK: - AztecNavigationController
//
class AztecNavigationController: UINavigationController {

    /// Returns the `AztecNavigationControllerDelegate`, if any.
    ///
    private var aztecDelegate: AztecNavigationControllerDelegate? {
        return delegate as? AztecNavigationControllerDelegate
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - Overriden Methods

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        guard let alertController = presentedViewController as? UIAlertController else {
            super.dismiss(animated: flag, completion: completion)
            return
        }

        super.dismiss(animated: flag, completion: completion)
        aztecDelegate?.navigationController(self, didDismiss: alertController)
    }
}
