import Foundation

class PartScreenPresentationController: FancyAlertPresentationController {

    var minimumHeight: CGFloat {
        return presentedViewController.preferredContentSize.height
    }

    private weak var tapGestureRecognizer: UITapGestureRecognizer?

    override var frameOfPresentedViewInContainerView: CGRect {
        /// If we are in compact mode, don't override the default
        guard traitCollection.verticalSizeClass != .compact else {
            return super.frameOfPresentedViewInContainerView
        }
        guard let containerView = containerView else {
            return .zero
        }
        let height = max(containerView.bounds.height/2, minimumHeight)
        let width = containerView.bounds.width

        return CGRect(x: 0, y: containerView.bounds.height - height, width: width, height: height)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { _ in
            self.presentedView?.frame = self.frameOfPresentedViewInContainerView
        }, completion: nil)
        super.viewWillTransition(to: size, with: coordinator)
    }

    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        presentedViewController.view.frame = frameOfPresentedViewInContainerView
    }

    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()

        if tapGestureRecognizer == nil {
            addGestureRecognizer()
        }
    }

    private func addGestureRecognizer() {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismiss))
        gestureRecognizer.cancelsTouchesInView = false
        gestureRecognizer.delegate = self
        containerView?.addGestureRecognizer(gestureRecognizer)
        tapGestureRecognizer = gestureRecognizer
    }

    /// This may need to be added to FancyAlertPresentationController
    override var shouldPresentInFullscreen: Bool {
        return false
    }

    @objc func dismiss() {
        presentedViewController.dismiss(animated: true, completion: nil)
    }
}

extension PartScreenPresentationController: UIGestureRecognizerDelegate {
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
