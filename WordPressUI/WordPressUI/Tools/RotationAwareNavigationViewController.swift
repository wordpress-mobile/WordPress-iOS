import UIKit

// MARK: - RotationAwareNavigationViewController
//
open class RotationAwareNavigationViewController: UINavigationController {

    /// Should Autorotate: Respect the top child's orientation prefs.
    ///
    override open var shouldAutorotate: Bool {
        return topViewController?.shouldAutorotate ?? super.shouldAutorotate
    }

    /// Supported Orientations: Respect the top child's orientation prefs.
    ///
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let supportedOrientations = topViewController?.supportedInterfaceOrientations {
            return supportedOrientations
        }

        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        return isPad ? .all : .allButUpsideDown
    }
}
