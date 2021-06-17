/// A transition animator that moves in the pushed view controller horizontally.
/// Does not handle the pop animation since the BloggingReminders setup flow does not allow to navigate back.
class BloggingRemindersAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.2
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {

        guard let sourceViewController =
                transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
              let destinationViewController =
                transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else {

            return
        }
        // final position of the destination view
        let endFrame = transitionContext.finalFrame(for: destinationViewController)

        // initial position of the destination view
        let startFrame = endFrame.offsetBy(dx: endFrame.width, dy: .zero)
        destinationViewController.view.frame = startFrame

        sourceViewController.view.alpha = .zero
        transitionContext.containerView.insertSubview(destinationViewController.view, aboveSubview: sourceViewController.view)

        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       animations: {
                        destinationViewController.view.frame = endFrame
                       }, completion: {_ in
                        transitionContext.completeTransition(true)
                       })
    }
}
