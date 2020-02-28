class PullDownAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    enum TransitionType {
        case presenting
        case dismissing
    }

    private let transitionType: TransitionType

    init(transitionType: TransitionType) {
        self.transitionType = transitionType
        super.init()
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toView: UIView = transitionContext.view(forKey: .to) ?? transitionContext.viewController(forKey: .to)?.view else { return }
        guard let fromView: UIView = transitionContext.view(forKey: .from) ?? transitionContext.viewController(forKey: .from)?.view else { return }
        let inView = transitionContext.containerView
        let presentedViewController = transitionContext.viewController(forKey: .to)

        let animationBlock: () -> Void
        switch transitionType {
        case .presenting:
            let presentingFrame = presentedViewController?.presentationController?.frameOfPresentedViewInContainerView ?? .zero
            toView.frame = CGRect(origin: CGPoint(x: fromView.safeAreaInsets.left, y: inView.frame.maxY), size: presentingFrame.size)
            inView.addSubview(toView)
            animationBlock = {
                toView.frame = presentingFrame
            }
        case .dismissing:
            let dismissingFrame = CGRect(x: toView.safeAreaInsets.left, y: toView.frame.maxY, width: fromView.bounds.width, height: fromView.frame.size.height)
            animationBlock = {
                fromView.frame = dismissingFrame
            }
        }

        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: animationBlock, completion: { finished in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }
}
