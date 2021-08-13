/// A transition animator that moves in the pushed view controller horizontally.
/// Does not handle the pop animation since the BloggingReminders setup flow does not allow to navigate back.
class BloggingRemindersAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    var popStyle = false

    private static let animationDuration: TimeInterval = 0.2
    private static let sourceEndFrameOffset: CGFloat = -60.0

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return Self.animationDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {

        guard !popStyle else {
            animatePop(using: transitionContext)
            return
        }

        guard let sourceViewController =
                transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
              let destinationViewController =
                transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else {
            return
        }
        // final position of the destination view
        let destinationEndFrame = transitionContext.finalFrame(for: destinationViewController)
        // final position of the source view
        let sourceEndFrame = transitionContext.initialFrame(for: sourceViewController).offsetBy(dx: Self.sourceEndFrameOffset, dy: .zero)

        // initial position of the destination view
        let destinationStartFrame = destinationEndFrame.offsetBy(dx: destinationEndFrame.width, dy: .zero)
        destinationViewController.view.frame = destinationStartFrame

        transitionContext.containerView.insertSubview(destinationViewController.view, aboveSubview: sourceViewController.view)

        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       animations: {
                        destinationViewController.view.frame = destinationEndFrame
                        sourceViewController.view.frame = sourceEndFrame
                       }, completion: {_ in
                        transitionContext.completeTransition(true)
                       })
    }

    func animatePop(using transitionContext: UIViewControllerContextTransitioning) {
        guard let sourceViewController =
                transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
              let destinationViewController =
                transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else {
            return
        }
        let destinationEndFrame = transitionContext.finalFrame(for: destinationViewController)
        let destinationStartFrame = destinationEndFrame.offsetBy(dx: Self.sourceEndFrameOffset, dy: .zero)
        destinationViewController.view.frame = destinationStartFrame
        transitionContext.containerView.insertSubview(destinationViewController.view, belowSubview: sourceViewController.view)

        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       animations: {
                        destinationViewController.view.frame = destinationEndFrame
                        sourceViewController.view.transform = sourceViewController.view.transform.translatedBy(x: sourceViewController.view.frame.width, y: 0)
                       }, completion: {_ in
                        transitionContext.completeTransition(true)
                       })
    }
}
