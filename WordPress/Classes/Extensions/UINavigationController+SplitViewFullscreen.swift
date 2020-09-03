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
        guard let splitViewController = splitViewController, splitViewController.preferredDisplayMode != .primaryHidden else {
            pushViewController(viewController, animated: animated)
            return
        }

        if let splitViewController = splitViewController as? WPSplitViewController,
            splitViewController.fullscreenDisplayEnabled == false {
            pushViewController(viewController, animated: animated)
            return
        }

        let performTransition = { (animated: Bool) in
            if !self.splitViewControllerIsHorizontallyCompact {
                self.navigationBar.fadeOutNavigationItems(animated: animated)
            }

            (splitViewController as? WPSplitViewController)?.setPrimaryViewControllerHidden(true, animated: animated)

            self.pushViewController(viewController, animated: animated)
        }

        if UIAccessibility.isReduceMotionEnabled && !self.splitViewControllerIsHorizontallyCompact {
            splitViewController.view.hideWithBlankingSnapshot(afterScreenUpdates: true)
            performTransition(false)
        } else {
            performTransition(animated)
        }
    }
}

// UIView hiding for use when "Reduce Motion" is enabled
//
extension UIView {
    private static let blankingSnapshotFadeDuration: TimeInterval = 0.3

    // Private class used so we can locate an existing blanking view
    private class BlankingView: UIView {}


    /// Hides this view by inserting a snapshot into the view hierarchy.
    ///
    /// - Parameter afterScreenUpdates: A Boolean value that specifies whether 
    ///             the snapshot should be taken after recent changes have been 
    ///             incorporated. Pass the value false to capture the screen in 
    ///             its current state, which might not include recent changes.
    @objc func hideWithBlankingSnapshot(afterScreenUpdates: Bool = false) {
        if subviews.first is BlankingView {
            return
        }

        let blankingView = BlankingView(frame: bounds)

        if let snapshot = snapshotView(afterScreenUpdates: afterScreenUpdates) {
            blankingView.addSubview(snapshot)
        }

        addSubview(blankingView)
    }


    /// Animates away any existing blanking snapshot.
    @objc func fadeOutAndRemoveBlankingSnapshot() {
        guard let blankingView = subviews.last as? BlankingView else {
            return
        }

        UIView.animate(withDuration: UIView.blankingSnapshotFadeDuration,
                       animations: {
                        blankingView.alpha = WPAlphaZero
        }, completion: { _ in
            blankingView.removeFromSuperview()
        })
    }
}

extension UINavigationBar {
    @objc func fadeOutNavigationItems(animated: Bool = true) {
        fadeNavigationItems(withTintColor: .appBarBackground, textColor: .appBarBackground, animated: animated)
    }

    @objc func fadeInNavigationItemsIfNecessary(animated: Bool = true) {
        fadeNavigationItems(withTintColor: .appBarTint, textColor: .appBarText, animated: animated)
    }

    private func fadeNavigationItems(withTintColor tintColor: UIColor, textColor: UIColor, animated: Bool) {
        if animated {
            // We're using CAAnimation because the various navigation item properties
            // didn't seem to animate using a standard UIView animation block.
            let fadeAnimation = CATransition()
            fadeAnimation.duration = fadeAnimationDuration
            fadeAnimation.type = CATransitionType.fade

            layer.add(fadeAnimation, forKey: "fadeNavigationBar")
        }

        self.tintColor = tintColor

        var attributes = titleTextAttributes
        attributes?[.foregroundColor] = textColor
        titleTextAttributes = attributes
    }
}

/// This transition replicates, as closely as possible, the standard
/// UINavigationController push / pop transition but replaces the from view
/// controller's view with a snapshot to avoid layout issues when transitioning
/// from or to a fullscreen split view layout.
///
class WPFullscreenNavigationTransition: NSObject, UIViewControllerAnimatedTransitioning {
    @objc static let transitionDuration: TimeInterval = 0.3

    @objc let operation: UINavigationController.Operation

    @objc var pushing: Bool {
        return operation == .push
    }

    @objc init(operation: UINavigationController.Operation) {
        self.operation = operation
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return WPFullscreenNavigationTransition.transitionDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard operation != .none else {
            transitionContext.completeTransition(false)
            return
        }

        guard let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from),
            let toView = transitionContext.view(forKey: UITransitionContextViewKey.to) else {
                transitionContext.completeTransition(false)
                return
        }

        guard let model = WPFullscreenNavigationTransitionViewModel(transitionContext: transitionContext, operation: operation) else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView

        // The default navigation bar transition sometimes has a small white
        // area visible briefly on the right end of the navigation bar as it's
        // transitioning to full screen width (but not yet wide enough).
        // This mask view sits behind the navigation bar and hides it.
        let navigationBarMask = UIView()
        navigationBarMask.backgroundColor = .primary
        containerView.addSubview(navigationBarMask)
        navigationBarMask.frame = model.navigationBarMaskFrame

        // Ensure the from view is the correct size when we start
        fromView.frame = model.fromFrame
        toView.frame = model.toFrame

        toView.transform = model.toViewInitialTranform

        // Take a snapshot to hide any layout issues in the 'from' view as it
        // transitions to the new size.
        let snapshot = fromView.snapshotView(afterScreenUpdates: false)!
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

            containerView.insertSubview(toView, at: 0)

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

            fromView.transform = .identity
            toView.transform = .identity

            fromView.frame = model.fromFrame

            transitionContext.completeTransition(finished)
        }

        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       delay: 0,
                       options: .curveEaseInOut,
                       animations: animations,
                       completion: completion)
    }
}

private struct WPFullscreenNavigationTransitionViewModel {
    let transitionContext: UIViewControllerContextTransitioning

    let fromFrame: CGRect
    let toFrame: CGRect

    let toViewInitialTranform: CGAffineTransform
    let toViewFinalTranform: CGAffineTransform = .identity

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

    init?(transitionContext: UIViewControllerContextTransitioning, operation: UINavigationController.Operation) {
        guard let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else {
                return nil
        }

        self.transitionContext = transitionContext

        // Frames

        fromFrame = transitionContext.initialFrame(for: fromVC)
        toFrame = transitionContext.finalFrame(for: toVC)

        // RTL support

        let layoutDirection = transitionContext.containerView.userInterfaceLayoutDirection()
        let isRTLLayout = (layoutDirection == .rightToLeft)

        // Transforms

        if operation == .push {
            let initialToViewXOrigin = (isRTLLayout) ? -fromFrame.width : fromFrame.width
            toViewInitialTranform = CGAffineTransform(translationX: initialToViewXOrigin, y: 0)
        } else {
            toViewInitialTranform = splitViewWidthTransform(forViewController: fromVC, isRTLLayout: isRTLLayout)
        }

        if operation == .push {
            snapshotContainerFinalTransform = splitViewWidthTransform(forViewController: fromVC, isRTLLayout: isRTLLayout)
        } else {
            let targetXOffset = (isRTLLayout) ? -fromFrame.width : toFrame.width
            snapshotContainerFinalTransform = CGAffineTransform(translationX: targetXOffset, y: 0)
        }

        // Navigation bar mask

        navigationBarMaskFrame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: fromFrame.origin.y)

        // Shadow layer

        let shadowXOffset = (isRTLLayout) ? fromFrame.width : -shadowWidth
        shadowFrame = CGRect(x: shadowXOffset, y: 0, width: shadowWidth, height: fromFrame.height)

        if isRTLLayout {
            shadowColors = [shadowDarkColor.cgColor, shadowClearColor.cgColor]
        } else {
            shadowColors = [shadowClearColor.cgColor, shadowDarkColor.cgColor]
        }

        // Dimming view

        let dimmingViewXOffset = (isRTLLayout) ? fromFrame.width : -fromFrame.width
        dimmingViewFrame = CGRect(x: dimmingViewXOffset, y: 0, width: fromFrame.width, height: fromFrame.height)
        dimmingViewInitialAlpha = (operation == .push) ? WPAlphaZero : WPAlphaFull
        dimmingViewFinalAlpha =   (operation == .push) ? WPAlphaFull : WPAlphaZero
    }
}

private func splitViewWidthTransform(forViewController viewController: UIViewController, isRTLLayout: Bool) -> CGAffineTransform {
    if let splitViewPrimaryWidth = viewController.splitViewController?.primaryColumnWidth, isRTLLayout {
        return CGAffineTransform(translationX: splitViewPrimaryWidth, y: 0)
    } else {
        return .identity
    }
}
