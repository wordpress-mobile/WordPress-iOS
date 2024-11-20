import UIKit

/// Presents a view controller with a dimming view behind that slowly fades in
/// as the presented view controller slides up.
///
open class FancyAlertPresentationController: UIPresentationController, UIViewControllerTransitioningDelegate {
    private struct Constants {
        static let dimmingViewAlpha: CGFloat = 0.5
    }

    private let dimmingView: UIView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.backgroundColor = UIColor(white: 0.0, alpha: Constants.dimmingViewAlpha)
        $0.alpha = 0
        return $0
    }(UIView())

    override open func presentationTransitionWillBegin() {
        guard let containerView else { return }

        containerView.addSubview(dimmingView)
        containerView.pinSubviewToAllEdges(dimmingView)

        guard let transitionCoordinator = presentingViewController.transitionCoordinator else {
            dimmingView.alpha = 1
            return
        }

        transitionCoordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 1
        })
    }

    override open func presentationTransitionDidEnd(_ completed: Bool) {
        if !completed {
            dimmingView.removeFromSuperview()
        }
    }

    override open func dismissalTransitionWillBegin() {
        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 0
            return
        }

        coordinator.animate(alongsideTransition: {
            _ in
            self.dimmingView.alpha = 0
        })
    }

    open func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        guard presented == self.presentedViewController,
            presenting == self.presentingViewController else {
                return nil
        }

        return self
    }
}
