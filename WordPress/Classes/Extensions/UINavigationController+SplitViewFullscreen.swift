import WordPressShared

private let fadeAnimationDuration: NSTimeInterval = 0.1

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
    func pushFullscreenViewController(viewController: UIViewController, animated: Bool) {
        if splitViewController?.preferredDisplayMode != .PrimaryHidden {
            if !splitViewControllerIsHorizontallyCompact {
                navigationBar.fadeOutNavigationItems(animated)
            }

            (splitViewController as? WPSplitViewController)?.setPrimaryViewControllerHidden(true, animated: animated)
        }

        pushViewController(viewController, animated: animated)
    }
}

extension UINavigationBar {
    func fadeOutNavigationItems(animated: Bool = true) {
        if let barTintColor = barTintColor {
            fadeNavigationItemsToColor(barTintColor, animated: animated)
        }
    }

    func fadeInNavigationItemsIfNecessary(animated: Bool = true) {
        if tintColor != UIColor.whiteColor() {
            fadeNavigationItemsToColor(UIColor.whiteColor(), animated: animated)
        }
    }

    private func fadeNavigationItemsToColor(color: UIColor, animated: Bool) {
        if animated {
            // We're using CAAnimation because the various navigation item properties
            // didn't seem to animate using a standard UIView animation block.
            let fadeAnimation = CATransition()
            fadeAnimation.duration = fadeAnimationDuration
            fadeAnimation.type = kCATransitionFade

            layer.addAnimation(fadeAnimation, forKey: "fadeNavigationBar")
        }

        titleTextAttributes = [NSForegroundColorAttributeName: color]
        tintColor = color

        // We're using UIAppearance for UIBarButtonItems because this seems to be
        // the only way to style the appearance of an incoming back button
        // when pushing a new view controller onto a navigation stack.
        //
        // Obviously this affects all newly-created UIBarButtonItems, but the
        // intention is that the color will be flipped back to default after
        // a push / pop transition has taken place.
        let attributes = [NSForegroundColorAttributeName: color]
        UIBarButtonItem.appearance().tintColor = color
        UIBarButtonItem.appearance().setTitleTextAttributes(attributes, forState: .Normal)
        UIBarButtonItem.appearance().setTitleTextAttributes(attributes, forState: .Selected)
        UIBarButtonItem.appearance().setTitleTextAttributes(attributes, forState: .Highlighted)
    }
}
