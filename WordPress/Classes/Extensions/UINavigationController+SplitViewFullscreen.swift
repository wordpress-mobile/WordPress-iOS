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
            let toView = transitionContext.viewForKey(UITransitionContextToViewKey) else {
                transitionContext.completeTransition(false)
                return
        }

        guard let model = WPFullscreenNavigationTransitionViewModel(transitionContext: transitionContext, operation: operation) else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView()

        // The default navigation bar transition sometimes has a small white
        // area visible briefly on the right end of the navigation bar as it's
        // transitioning to full screen width (but not yet wide enough).
        // This mask view sits behind the navigation bar and hides it.
        let navigationBarMask = UIView()
        navigationBarMask.backgroundColor = WPStyleGuide.wordPressBlue()
        containerView.addSubview(navigationBarMask)
        navigationBarMask.frame = model.navigationBarMaskFrame

        // Ensure the from view is the correct size when we start
        fromView.frame = model.fromFrame
        toView.frame = model.toFrame

        toView.transform = model.toViewInitialTranform

        // Take a snapshot to hide any layout issues in the 'from' view as it
        // transitions to the new size.
        let snapshot = fromView.snapshotViewAfterScreenUpdates(false)!
        let snapshotContainer = UIView(frame: model.fromFrame)
        snapshotContainer.backgroundColor = fromView.backgroundColor
        snapshotContainer.addSubview(snapshot)

        // Add a thin shadow gradient down the leading edge of the topmost view,
        // matching the appearance of the standard UINavigationController transition.
        let shadowLayer = CAGradientLayer()
        shadowLayer.locations = [0, 1]
        shadowLayer.colors = model.shadowColors
        shadowLayer.frame = model.shadowFrame
        shadowLayer.startPoint = model.shadowStartPoint
        shadowLayer.endPoint = model.shadowEndPoint

        // Dim out the bottommost view, matching the appearance of the standard
        // UINavigationController transition.
        let dimmingView = UIView(frame: model.dimmingViewFrame)
        dimmingView.backgroundColor = model.dimmingViewColor
        dimmingView.alpha = model.dimmingViewInitialAlpha

        containerView.addSubview(snapshotContainer)

        if pushing {
            containerView.addSubview(toView)

            toView.layer.addSublayer(shadowLayer)
            toView.addSubview(dimmingView)
        } else {
            fromView.alpha = WPAlphaZero

            containerView.insertSubview(toView, atIndex: 0)

            snapshotContainer.layer.addSublayer(shadowLayer)
            snapshotContainer.addSubview(dimmingView)
        }

        let animations = {
            toView.transform = model.toViewFinalTranform
            snapshotContainer.transform = model.snapshotContainerFinalTransform

            dimmingView.alpha = model.dimmingViewFinalAlpha
        }

        let completion = { (finished: Bool) in
            dimmingView.removeFromSuperview()
            fromView.removeFromSuperview()

            shadowLayer.removeFromSuperlayer()
            snapshotContainer.removeFromSuperview()

            fromView.transform = CGAffineTransformIdentity
            toView.transform = CGAffineTransformIdentity

            fromView.frame = model.fromFrame

            transitionContext.completeTransition(finished)
        }

        UIView.animateWithDuration(transitionDuration(transitionContext),
                                   delay: 0,
                                   options: .CurveEaseInOut,
                                   animations: animations,
                                   completion: completion)
    }
}

private struct WPFullscreenNavigationTransitionViewModel {
    let transitionContext: UIViewControllerContextTransitioning

    let fromFrame: CGRect
    let toFrame: CGRect

    let toViewInitialTranform: CGAffineTransform
    let toViewFinalTranform = CGAffineTransformIdentity

    let snapshotContainerFinalTransform: CGAffineTransform

    let navigationBarMaskFrame: CGRect

    let shadowWidth: CGFloat = 5.0
    let shadowColors: [CGColor]
    let shadowFrame: CGRect
    let shadowStartPoint = CGPoint(x: 0, y: 0.5) // Center left
    let shadowEndPoint =   CGPoint(x: 1, y: 0.5) // Center right
    private let shadowClearColor = UIColor(white: 0, alpha: 0)
    private let shadowDarkColor = UIColor(white: 0, alpha: 0.1)

    let dimmingViewColor = UIColor(white: 0, alpha: 0.05)
    let dimmingViewFrame: CGRect
    let dimmingViewInitialAlpha: CGFloat
    let dimmingViewFinalAlpha: CGFloat

    init?(transitionContext: UIViewControllerContextTransitioning, operation: UINavigationControllerOperation) {
        guard let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey),
            let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) else {
                return nil
        }

        self.transitionContext = transitionContext

        // Frames

        fromFrame = transitionContext.initialFrameForViewController(fromVC)
        toFrame = transitionContext.finalFrameForViewController(toVC)

        // RTL support

        let attribute = transitionContext.containerView().semanticContentAttribute
        let layoutDirection = UIView.userInterfaceLayoutDirectionForSemanticContentAttribute(attribute)
        let isRTLLayout = (layoutDirection == .RightToLeft)

        // Transforms

        if operation == .Push {
            let initialToViewXOrigin = (isRTLLayout) ? -fromFrame.width : fromFrame.width
            toViewInitialTranform = CGAffineTransformMakeTranslation(initialToViewXOrigin, 0)
        } else {
            toViewInitialTranform = splitViewWidthTransformForViewController(fromVC, isRTLLayout: isRTLLayout)
        }

        if operation == .Push {
            snapshotContainerFinalTransform = splitViewWidthTransformForViewController(fromVC, isRTLLayout: isRTLLayout)
        } else {
            let targetXOffset = (isRTLLayout) ? -fromFrame.width : toFrame.width
            snapshotContainerFinalTransform = CGAffineTransformMakeTranslation(targetXOffset, 0)
        }

        // Navigation bar mask

        navigationBarMaskFrame = CGRect(x: 0, y: 0, width: UIScreen.mainScreen().bounds.width, height: fromFrame.origin.y)

        // Shadow layer

        let shadowXOffset = (isRTLLayout) ? fromFrame.width : -shadowWidth
        shadowFrame = CGRect(x: shadowXOffset, y: 0, width: shadowWidth, height: fromFrame.height)

        if isRTLLayout {
            shadowColors = [shadowDarkColor.CGColor, shadowClearColor.CGColor]
        } else {
            shadowColors = [shadowClearColor.CGColor, shadowDarkColor.CGColor]
        }

        // Dimming view

        let dimmingViewXOffset = (isRTLLayout) ? fromFrame.width : -fromFrame.width
        dimmingViewFrame = CGRect(x: dimmingViewXOffset, y: 0, width: fromFrame.width, height: fromFrame.height)
        dimmingViewInitialAlpha = (operation == .Push) ? WPAlphaZero : WPAlphaFull
        dimmingViewFinalAlpha =   (operation == .Push) ? WPAlphaFull : WPAlphaZero
    }
}

private func splitViewWidthTransformForViewController(viewController: UIViewController, isRTLLayout: Bool) -> CGAffineTransform {
    if let splitViewPrimaryWidth = viewController.splitViewController?.primaryColumnWidth where isRTLLayout {
        return CGAffineTransformMakeTranslation(splitViewPrimaryWidth, 0)
    } else {
        return CGAffineTransformIdentity
    }
}
