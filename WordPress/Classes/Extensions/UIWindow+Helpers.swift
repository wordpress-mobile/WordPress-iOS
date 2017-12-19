import UIKit

extension UIWindow {
    /// Returns the view controller at the top of the view hierarchy.
    @objc var topmostPresentedViewController: UIViewController? {
        guard var controller = rootViewController else {
            return nil
        }
        while let presented = controller.presentedViewController {
            controller = presented
        }
        return controller
    }
}
