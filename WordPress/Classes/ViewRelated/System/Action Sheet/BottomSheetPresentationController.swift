/// A Presentation Controller which dims the background, allows the user to dismiss by tapping outside, and allows the user to swipit down
class BottomSheetPresentationController: FancyAlertPresentationController {

    private weak var tapGestureRecognizer: UITapGestureRecognizer?
    private weak var panGestureRecognizer: UIPanGestureRecognizer?

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        let height: CGFloat = presentedViewController.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        let width: CGFloat = (containerView?.bounds.width ?? 0) - ((containerView?.safeAreaInsets.left ?? 0) + (containerView?.safeAreaInsets.right ?? 0))

        return CGRect(x: containerView?.safeAreaInsets.left ?? 0, y: (containerView?.bounds.height ?? 0) - height, width: width, height: height)
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
