import WordPressShared

fileprivate let fadeAnimationDuration: TimeInterval = 0.1

// UISplitViewController doesn't handle pushing or popping a view controller
// at the same time as animating the preferred display mode very well.
// In the best case, you end up with a visual 'jump' as the navigation
// bar skips from the large size to the small size. It doesn't look very good.
//
// To counteract this, these methods are used to fade out the navigation items
// of a navigation bar as we perform a push / pop and change the fullscreen
// status, and then restore the items color afterwards – thus masking the
// UIKit glitch.
extension UINavigationController {
    @objc func pushFullscreenViewController(_ viewController: UIViewController, animated: Bool) {
        guard let splitViewController = splitViewController, splitViewController.preferredDisplayMode != .secondaryOnly else {
            pushViewController(viewController, animated: animated)
            return
        }

        if let splitViewController = splitViewController as? WPSplitViewController,
            splitViewController.fullscreenDisplayEnabled == false {
            pushViewController(viewController, animated: animated)
            return
        }

        let performTransition = { (animated: Bool) in
            (splitViewController as? WPSplitViewController)?.setPrimaryViewControllerHidden(true, animated: animated)

            self.pushViewController(viewController, animated: animated)
        }

        if UIAccessibility.isReduceMotionEnabled && !self.splitViewControllerIsHorizontallyCompact {
            performTransition(false)
        } else {
            performTransition(animated)
        }
    }
}
