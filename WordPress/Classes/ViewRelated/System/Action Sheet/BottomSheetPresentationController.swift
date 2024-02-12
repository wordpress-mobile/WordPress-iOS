import WordPressUI

/// A Presentation Controller which dims the background, allows the user to dismiss by tapping outside, and allows the user to swipit down
class BottomSheetPresentationController: FancyAlertPresentationController {

    private enum Constants {
        static let maxWidthPercentage: CGFloat = 0.66 /// Used to constrain the width to a smaller size (instead of full width) when sheet is too wide
        static let topSpacing: CGFloat = 16.0
    }

    private weak var tapGestureRecognizer: UITapGestureRecognizer?
    private weak var panGestureRecognizer: UIPanGestureRecognizer?

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else { /// If we don't have a container view we're out of luck
            return .zero
        }

        let topSpacing = traitCollection.verticalSizeClass == .regular ? Constants.topSpacing : .zero
        let maxHeight = containerView.bounds.height - containerView.safeAreaInsets.top - topSpacing
        /// Height calculated by autolayout or a set maximum, Width equal to the container view minus insets
        let height: CGFloat = min(presentedViewController.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height, maxHeight)
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

        switch gesture.state {
        case .began:
            /// Begin the dismissal transition
            interactionController = UIPercentDrivenInteractiveTransition()
            dismiss()
        case .changed:
            /// Update the transition based on our calculated percent of completion
            interactionController?.update(percent)
        case .ended:
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
        case .cancelled:
            interactionController?.cancel()
            interactionController = nil
        default:
            break
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
