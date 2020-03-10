/// A Presentation Controller which dims the background, allows the user to dismiss by tapping outside, and allows the user to swipit down
class BottomSheetPresentationController: FancyAlertPresentationController {

    private enum Constants {
        static let maxWidthPercentage: CGFloat = 0.66 /// Used to constrain the width to a smaller size (instead of full width) when sheet is too wide
    }

    private weak var tapGestureRecognizer: UITapGestureRecognizer?
    private weak var panGestureRecognizer: UIPanGestureRecognizer?

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else { /// If we don't have a container view we're out of luck
            return .zero
        }

        /// Height calculated by autolayout, Width equal to the container view minus insets
        let height: CGFloat = presentedViewController.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        var width: CGFloat = containerView.bounds.width - (containerView.safeAreaInsets.left + containerView.safeAreaInsets.right)

        /// If we're in a compact vertical size class, constrain the width a bit more so it doesn't get overly wide.
        if traitCollection.verticalSizeClass == .compact {
            width = width * Constants.maxWidthPercentage
        }

        /// If we constrain the width, this centers the view by applying the appropriate insets based on width
        let leftInset: CGFloat = ((containerView.bounds.width - width) / 2)

        return CGRect(x: leftInset, y: containerView.bounds.height - height, width: width, height: height)
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
            /// Begin the dismissal transition
            interactionController = UIPercentDrivenInteractiveTransition()
            dismiss()
        } else if gesture.state == .changed {
            /// Update the transition based on our calculated percent of completion
            interactionController?.update(percent)
        } else if gesture.state == .ended {
            /// Calculate the velocity of the ended gesture.
            /// - If the gesture has no downward velocity but is greater than half way down, complete the dismissal
            /// - If there is downward velocity, dismiss
            /// - If the gesture has no downward velocity and is less than half way down, cancel the dismissal
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
