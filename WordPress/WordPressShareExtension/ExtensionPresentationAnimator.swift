import UIKit

final class ExtensionPresentationAnimator: NSObject {

    // MARK: - Properties

    let direction: Direction
    let isPresentation: Bool

    // MARK: - Initializers

    init(direction: Direction, isPresentation: Bool) {
        self.direction = direction
        self.isPresentation = isPresentation
        super.init()
    }
}

// MARK: - UIViewControllerAnimatedTransitioning Conformance

extension ExtensionPresentationAnimator: UIViewControllerAnimatedTransitioning {

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return Constants.animationDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let key: UITransitionContextViewControllerKey = isPresentation ? UITransitionContextViewControllerKey.to : UITransitionContextViewControllerKey.from
        let controller: UIViewController = transitionContext.viewController(forKey: key)!

        if isPresentation {
            transitionContext.containerView.addSubview(controller.view)
        }

        let presentedFrame: CGRect = transitionContext.finalFrame(for: controller)
        var dismissedFrame: CGRect = presentedFrame

        let contextFrame: CGRect = transitionContext.containerView.frame

        switch direction {
        case .left:
            dismissedFrame.origin.x = -presentedFrame.width
        case .right:
            dismissedFrame.origin.x = contextFrame.width
        case .top:
            dismissedFrame.origin.y = -presentedFrame.height
        case .bottom:
            dismissedFrame.origin.y = contextFrame.height
        }

        let initialFrame: CGRect = isPresentation ? dismissedFrame : presentedFrame
        let finalFrame: CGRect = isPresentation ? presentedFrame : dismissedFrame

        let animationDuration: TimeInterval = transitionDuration(using: transitionContext)
        controller.view.frame = initialFrame
        UIView.animate(withDuration: animationDuration, animations: {
            controller.view.frame = finalFrame
        }) { (finished: Bool) in
            transitionContext.completeTransition(finished)
        }
    }
}

// MARK: - Constants

private extension ExtensionPresentationAnimator {
    struct Constants {
        static let animationDuration: Double = 0.33
    }
}
