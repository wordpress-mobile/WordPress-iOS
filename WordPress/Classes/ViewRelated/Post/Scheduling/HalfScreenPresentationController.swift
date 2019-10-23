import Foundation

// Should be added to WordpressUI?
class HalfScreenPresentationController: FancyAlertPresentationController {

    fileprivate weak var tapGestureRecognizer: UITapGestureRecognizer?

    override var frameOfPresentedViewInContainerView: CGRect {
        let height = containerView?.bounds.height ?? 0
        let width = containerView?.bounds.width ?? 0
        return CGRect(x: 0, y: height/2, width: width, height: height/2)
    }

    override func containerViewDidLayoutSubviews() {
        if tapGestureRecognizer == nil {
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismiss))
            gestureRecognizer.cancelsTouchesInView = false
            gestureRecognizer.delegate = self
            containerView?.addGestureRecognizer(gestureRecognizer)
            tapGestureRecognizer = gestureRecognizer
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if size.width > size.height {
            let height = containerView?.bounds.height ?? 0
            let width = containerView?.bounds.width ?? 0
            presentedView?.frame = CGRect(x: 0, y: 0, width: width, height: height)
        } else {
            let height = containerView?.bounds.height ?? 0
            let width = containerView?.bounds.width ?? 0
            presentedView?.frame = CGRect(x: 0, y: height/2, width: width, height: height/2)
        }
    }

    // This may need to be added to FancyAlertPresentationController
    override var shouldPresentInFullscreen: Bool {
        return false
    }

    @objc func dismiss() {
        presentedViewController.dismiss(animated: true, completion: nil)
    }
}

extension HalfScreenPresentationController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let containerView = containerView, let presentedView = presentedView {
            let touchPoint = touch.location(in: containerView)
            let isInPresentedView = presentedView.frame.contains(touchPoint)

            // Do not accept the touch if inside of the presented view
            return (gestureRecognizer == tapGestureRecognizer) && isInPresentedView == false
        } else {
            return false // Shouldn't happen; should always have container & presented view when tapped
        }
    }
}
