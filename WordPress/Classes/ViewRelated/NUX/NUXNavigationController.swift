import UIKit

/// Simple subclass of UINavigationController to facilitate a customized
/// appearance as part of the sign in flow.
///
@objc class NUXNavigationController: RotationAwareNavigationViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destination = segue.destination as? LoginEpilogueViewController,
            let source = segue.source as? NUXNavigationController else {
                return
        }
//        destination.dismissBlock = source.dismissBlock
        destination.originalPresentingVC = self.presentingViewController
    }
}
