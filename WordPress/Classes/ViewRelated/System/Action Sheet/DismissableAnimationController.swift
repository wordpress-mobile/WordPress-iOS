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

        func presentingFrame() -> CGRect {
            let height = (presentedViewController?.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height ?? 0) + (fromView.safeAreaInsets.bottom)
            let width = fromView.bounds.width
            return CGRect(x: 0, y: (fromView.bounds.height) - height, width: width, height: height)
        }

        let newFrame = transitionType == .presenting ? presentingFrame() : CGRect(x: 0, y: fromView.frame.maxY, width: fromView.bounds.width, height: fromView.frame.size.height)

        let animationBlock: () -> Void
        switch transitionType {
        case .presenting:
            toView.frame = CGRect(origin: CGPoint(x: 0, y: inView.frame.maxY), size: newFrame.size)
            inView.addSubview(toView)
            animationBlock = {
                toView.frame = newFrame
            }
        case .dismissing:
            animationBlock = {
                fromView.frame = newFrame
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

/// A Presentation Controller which dims the background, allows the user to dismiss by tapping outside, and allows the user to swipit down
class BottomSheetPresentationController: FancyAlertPresentationController {

    private weak var tapGestureRecognizer: UITapGestureRecognizer?
    private weak var panGestureRecognizer: UIPanGestureRecognizer?

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
    }

    override var frameOfPresentedViewInContainerView: CGRect {

        /// If we are in compact mode, don't override the default
        guard traitCollection.verticalSizeClass != .compact else {
            return super.frameOfPresentedViewInContainerView
        }

        let height = presentedViewController.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height + (containerView?.safeAreaInsets.bottom ?? 0)
        let width = containerView?.bounds.width ?? 0

        return CGRect(x: 0, y: (containerView?.bounds.height ?? 0) - height, width: width, height: height)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { _ in
            self.presentedView?.frame = self.frameOfPresentedViewInContainerView
        }, completion: nil)
        super.viewWillTransition(to: size, with: coordinator)
    }

    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
    }

    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()

        if tapGestureRecognizer == nil {
            addTapGestureRecognizer()
        }

        if panGestureRecognizer == nil {
            addPanGestureRecognizer()
        }
    }

    private func addTapGestureRecognizer() {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismiss))
        gestureRecognizer.cancelsTouchesInView = false
        gestureRecognizer.delegate = self
        containerView?.addGestureRecognizer(gestureRecognizer)
        tapGestureRecognizer = gestureRecognizer
    }

    private func addPanGestureRecognizer() {
        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(hide(_:)))
        presentedViewController.view.addGestureRecognizer(gestureRecognizer)
        panGestureRecognizer = gestureRecognizer
    }

    var interactionController: UIPercentDrivenInteractiveTransition?

    @objc func hide(_ gesture: UIPanGestureRecognizer) {

        guard let gestureView = gesture.view else { return }

        let translate = gesture.translation(in: gestureView)
        let percent   = translate.y / gestureView.bounds.size.height

        if gesture.state == .began {
            interactionController = UIPercentDrivenInteractiveTransition()
            dismiss()
        } else if gesture.state == .changed {
            interactionController?.update(percent)
        } else if gesture.state == .ended {
            let velocity = gesture.velocity(in: gesture.view)
            if (percent > 0.5 && velocity.y == 0) || velocity.y > 0 {
                interactionController?.finish()
            } else {
                interactionController?.cancel()
            }
            interactionController = nil
        }
    }

    @objc func dismiss() {
        presentedViewController.dismiss(animated: true, completion: nil)
    }
}

extension BottomSheetPresentationController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        /// Shouldn't happen; should always have container & presented view when tapped
        guard let containerView = containerView, let presentedView = presentedView else {
            return false
        }

        let touchPoint = touch.location(in: containerView)
        let isInPresentedView = presentedView.frame.contains(touchPoint)

        /// Do not accept the touch if inside of the presented view
        return (gestureRecognizer == tapGestureRecognizer) && isInPresentedView == false
    }
}
