import Foundation
import UIKit
import WordPressShared

class ExtensionPresentationController: UIPresentationController {

    // MARK: - Private Properties

    fileprivate var direction: Direction

    fileprivate let dimmingView: UIView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.backgroundColor = Appearance.dimmingViewBGColor
        $0.alpha = Constants.zeroAlpha
        return $0
    }(UIView())

    // MARK: - Initializers

    init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?, direction: Direction) {
        self.direction = direction
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }

    // MARK: - Presentation Controller Overrides

    override var frameOfPresentedViewInContainerView: CGRect {
        var frame: CGRect = .zero
        frame.size = size(forChildContentContainer: presentedViewController, withParentContainerSize: containerView!.bounds.size)
        frame.origin.x = (containerView!.frame.width - frame.width) / 2.0
        frame.origin.y = (containerView!.frame.height - frame.height) / 2.0
        return frame
    }

    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        return CGSize(width: (parentSize.width * Appearance.widthRatio), height: (parentSize.height * Appearance.heightRatio))
    }

    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
        presentedView?.layer.cornerRadius = Appearance.cornerRadius
        presentedView?.clipsToBounds = true
    }

    override func presentationTransitionWillBegin() {
        containerView?.insertSubview(dimmingView, at: 0)
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|[dimmingView]|", options: [], metrics: nil, views: ["dimmingView": dimmingView]))
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|[dimmingView]|", options: [], metrics: nil, views: ["dimmingView": dimmingView]))

        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = Constants.fullAlpha
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = Constants.fullAlpha
        })
    }

    override func dismissalTransitionWillBegin() {
        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = Constants.zeroAlpha
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = Constants.zeroAlpha
        })
    }
}

// MARK: - Constants

private extension ExtensionPresentationController {

    struct Appearance {
        static let dimmingViewBGColor = UIColor(white: 0.0, alpha: 0.5)
        static let cornerRadius: CGFloat = 13.0
        static let widthRatio: CGFloat = 0.95
        static let heightRatio: CGFloat = 0.90
    }
    struct Constants {
        static let fullAlpha: CGFloat = 1.0
        static let zeroAlpha: CGFloat = 0.0
    }
}
