import Foundation
import UIKit

extension UIViewController {
    /// Determines if the current ViewController's View is visible and onscreen
    ///
    public func isViewOnScreen() -> Bool {
        let visibleAsRoot = view.window?.rootViewController == self
        let visibleAsTopOnStack = navigationController?.topViewController == self && view.window != nil
        let visibleAsPresented = view.window?.rootViewController?.presentedViewController == self

        let isNotPresentingAView = presentedViewController == nil

        return isNotPresentingAView && (visibleAsRoot || visibleAsTopOnStack || visibleAsPresented)
    }

    /// Determines if the current ViewController's View is horizontally Compact
    ///
    public func hasHorizontallyCompactView() -> Bool {
        return traitCollection.horizontalSizeClass == .compact
    }

    /// Determines if the horizontal size class is specified or not.
    ///
    public func isHorizontalSizeClassUnspecified() -> Bool {
        return traitCollection.horizontalSizeClass == .unspecified
    }

    /// Determines if the current ViewController is being presented modally
    ///
    @objc public func isModal() -> Bool {
        if self.presentingViewController?.presentedViewController == self {
            return true
        } else if let navigationController = self.navigationController {
            if navigationController.presentingViewController != nil &&
                navigationController.presentingViewController?.presentedViewController == navigationController &&
                navigationController.children.first == self {
                return true
            }
        }
        return false
    }

    /// Returns the view controller at the top of the view hierarchy (AKA leaf).
    ///
    @objc public var topmostPresentedViewController: UIViewController {
        var controller = self
        while let presented = controller.presentedViewController {
            controller = presented
        }
        return controller
    }

    /// Returns the top-most view controller suitable for presenting on top of.
    public static var topViewController: UIViewController? {
        UIApplication.shared.delegate?.window??.topmostPresentedViewController
    }

    @objc public var splitViewControllerIsHorizontallyCompact: Bool {
        splitViewController?.hasHorizontallyCompactView() ?? hasHorizontallyCompactView()
    }
}
