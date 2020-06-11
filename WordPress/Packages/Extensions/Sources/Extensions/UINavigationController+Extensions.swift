import UIKit
/// Encapsulates UINavigationController Helper Methods.
///
extension UINavigationController {
    public func previousViewController() -> UIViewController? {
        guard viewControllers.count > 1 else {
            return nil
        }
        return viewControllers[viewControllers.count - 2]
    }
}
