import UIKit

extension UIWindow {
    /// Returns the view controller at the top of the view hierarchy.
    @objc public var topmostPresentedViewController: UIViewController? {
        return rootViewController?.topmostPresentedViewController
    }
}
