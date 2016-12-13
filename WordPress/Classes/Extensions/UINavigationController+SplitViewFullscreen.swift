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
    }
}

/// This transition replicates, as closely as possible, the standard
/// UINavigationController push / pop transition but replaces the from view
/// controller's view with a snapshot to avoid layout issues when transitioning
/// from or to a fullscreen split view layout.
///
class WPFullscreenNavigationTransition: NSObject, UIViewControllerAnimatedTransitioning {
    static let transitionDuration: NSTimeInterval = 0.4

    let operation: UINavigationControllerOperation

    var pushing: Bool {
        return operation == .Push
    }

    init(operation: UINavigationControllerOperation) {
        self.operation = operation
        super.init()
    }

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return WPFullscreenNavigationTransition.transitionDuration
    }

    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        guard operation != .None else {
            transitionContext.completeTransition(false)
            return
        }

        guard let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey),
            let toView = transitionContext.viewForKey(UITransitionContextToViewKey),
            let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey),
            let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) else {
                transitionContext.completeTransition(false)
                return
        }

        let fromFrame = transitionContext.initialFrameForViewController(fromVC)
        let targetFrame = transitionContext.finalFrameForViewController(toVC)

        let containerView = transitionContext.containerView()

        // The default navigation bar transition sometimes has a small white
        // area visible briefly on the right end of the navigation bar as it's
        // transitioning to full screen width (but not yet wide enough).
        // This mask view sits behind the navigation bar and hides it.
        let navigationBarMask = UIView()
        navigationBarMask.backgroundColor = WPStyleGuide.wordPressBlue()
        containerView.addSubview(navigationBarMask)
        navigationBarMask.frame = CGRect(x: 0, y: 0, width: UIScreen.mainScreen().bounds.width, height: fromFrame.origin.y)

        // Ensure the from view is the correct size when we start
        fromView.frame = fromFrame
        toView.frame = targetFrame

        // Take a snapshot to hide any layout issues in the 'from' view as it
        // transitions to the new size.
        let snapshot = fromView.snapshotViewAfterScreenUpdates(false)!

        // Add a shadow layer to the left edge of the topmost view, matching
        // the appearance of the standard UINavigationController transition.
        let shadowWidth: CGFloat = 5.0
        let shadowClearColor = UIColor(white: 0, alpha: 0).CGColor
        let shadowDarkColor = UIColor(white: 0, alpha: 0.1).CGColor

        let shadowLayer = CAGradientLayer()
        shadowLayer.colors = [shadowClearColor, shadowDarkColor]
        shadowLayer.locations = [0, 1]
        shadowLayer.frame = CGRect(x: -shadowWidth, y: 0, width: shadowWidth, height: fromFrame.height)

        let centerLeft = CGPoint(x: 0, y: 0.5)
        let centerRight = CGPoint(x: 1, y: 0.5)
        shadowLayer.startPoint = centerLeft
        shadowLayer.endPoint = centerRight

        // Dim out the bottommost view, matching the appearance of the standard
        // UINavigationController transition.
        let dimmingViewColor = UIColor(white: 0, alpha: 0.05)
        let dimmingView = UIView(frame: CGRect(x: -fromFrame.width, y: 0, width: fromFrame.width, height: fromFrame.height))
        dimmingView.backgroundColor = dimmingViewColor

        if pushing {
            snapshot.frame = fromFrame
            containerView.addSubview(snapshot)

            // Initially position the new VC offscreen
            toView.transform = CGAffineTransformMakeTranslation(fromFrame.width, 0)
            containerView.addSubview(toView)

            toView.layer.addSublayer(shadowLayer)
            toView.addSubview(dimmingView)
            dimmingView.alpha = WPAlphaZero
        } else {
            fromView.addSubview(snapshot)

            containerView.insertSubview(toView, atIndex: 0)

            fromView.layer.addSublayer(shadowLayer)
            fromView.addSubview(dimmingView)
            dimmingView.alpha = WPAlphaFull
        }

        let animations = {
            toView.transform = CGAffineTransformIdentity

            if self.pushing {
                // Transform off by 3/4 of the width for a bit of parallaxing
                fromView.transform = CGAffineTransformMakeTranslation(-targetFrame.width * 0.75, 0)
                dimmingView.alpha = WPAlphaFull
            } else {
                fromView.transform = CGAffineTransformMakeTranslation(targetFrame.width, 0)
                dimmingView.alpha = WPAlphaZero
            }
        }

        let completion = { (finished: Bool) in
            dimmingView.removeFromSuperview()
            fromView.removeFromSuperview()

            shadowLayer.removeFromSuperlayer()
            snapshot.removeFromSuperview()

            fromView.transform = CGAffineTransformIdentity
            toView.transform = CGAffineTransformIdentity

            fromView.frame = fromFrame

            transitionContext.completeTransition(finished)
        }

        UIView.animateWithDuration(transitionDuration(transitionContext),
                                   delay: 0,
                                   options: .CurveEaseOut,
                                   animations: animations,
                                   completion: completion)
    }
}
