
import UIKit

// MARK: - BottomSheetPresentationControllerConstants

private struct BottomSheetPresentationControllerConstants {
    static let cornerRadius         = CGFloat(16)
    static let transitionDuration   = TimeInterval(0.3)
}

// MARK: - BottomSheetPresentationController

///
/// BottomSheetPresentationController manages presentation of a view controller like a bottom sheet.
///
/// Adapted from AAPLCustomPresentationController, Custom View Controller Presentations and Transitions
/// https://developer.apple.com/library/archive/samplecode/CustomTransitions/Introduction/Intro.html#//apple_ref/doc/uid/TP40015158
///
class BottomSheetPresentationController: UIPresentationController {

    // MARK: Properties

    private(set) var dimmingView: UIView?
    private(set) var presentationWrappingView: UIView?

    // MARK: UIPresentationController

    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {

        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        presentedViewController.modalPresentationStyle = .custom
    }

    override var presentedView: UIView? {
        return self.presentationWrappingView
    }

    override func presentationTransitionWillBegin() {
        guard let containerView = containerView else {
            return
        }

        let presentationWrapperView = UIView(frame: frameOfPresentedViewInContainerView)
        self.presentationWrappingView = presentationWrapperView

        let presentationRoundedCornerInsets = UIEdgeInsets(top: 0, left: 0, bottom: -BottomSheetPresentationControllerConstants.cornerRadius, right: 0)
        let presentationRoundedCornerViewRect = presentationWrapperView.bounds.inset(by: presentationRoundedCornerInsets)
        let presentationRoundedCornerView = UIView(frame: presentationRoundedCornerViewRect)
        presentationRoundedCornerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        presentationRoundedCornerView.layer.cornerRadius = BottomSheetPresentationControllerConstants.cornerRadius
        presentationRoundedCornerView.layer.masksToBounds = true

        let presentedViewControllerWrapperInsets = UIEdgeInsets(top: 0, left: 0, bottom: BottomSheetPresentationControllerConstants.cornerRadius, right: 0)
        let presentedViewControllerWrapperViewRect = presentationRoundedCornerView.bounds.inset(by: presentedViewControllerWrapperInsets)
        let presentedViewControllerWrapperView = UIView(frame: presentedViewControllerWrapperViewRect)
        presentedViewControllerWrapperView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        guard let presentedViewControllerView = super.presentedView else {
            return
        }

        presentedViewControllerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        presentedViewControllerView.frame = presentedViewControllerWrapperView.bounds
        presentedViewControllerWrapperView.addSubview(presentedViewControllerView)

        presentationRoundedCornerView.addSubview(presentedViewControllerWrapperView)

        presentationWrapperView.addSubview(presentationRoundedCornerView)

        let dimmingView = UIView(frame: containerView.bounds)
        dimmingView.backgroundColor = WPStyleGuide.darkGrey()
        dimmingView.isOpaque = false
        dimmingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(dimmingViewTapped))
        dimmingView.addGestureRecognizer(tapRecognizer)

        self.dimmingView = dimmingView
        containerView.addSubview(dimmingView)

        let coordinator = presentingViewController.transitionCoordinator

        dimmingView.alpha = 0
        coordinator?.animate(alongsideTransition: { [weak self] context in
            self?.dimmingView?.alpha = 0.5
        })
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        guard completed == false else {
            return
        }

        presentationWrappingView = nil
        dimmingView = nil
    }

    override func dismissalTransitionWillBegin() {
        let coordinator = presentingViewController.transitionCoordinator

        coordinator?.animate(alongsideTransition: { [weak self] context in
            self?.dimmingView?.alpha = 0
        })
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        guard completed else {
            return
        }

        presentationWrappingView = nil
        dimmingView = nil
    }

    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)

        if let containerViewController = container as? UIViewController,
            containerViewController == presentedViewController {

            containerView?.setNeedsLayout()
        }
    }

    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {

        if let containerViewController = container as? UIViewController,
            containerViewController == presentedViewController {

            return containerViewController.preferredContentSize
        } else {
            return super.size(forChildContentContainer: container, withParentContainerSize: parentSize)
        }
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        let containerViewBounds = containerView?.bounds ?? .zero
        let presentedViewContentSize = size(forChildContentContainer: presentedViewController, withParentContainerSize: containerViewBounds.size)

        var presentedViewControllerFrame = containerViewBounds
        presentedViewControllerFrame.size.height = presentedViewContentSize.height
        presentedViewControllerFrame.origin.y = containerViewBounds.maxY - presentedViewContentSize.height

        return presentedViewControllerFrame
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()

        if let containerBounds = containerView?.bounds {
            dimmingView?.frame = containerBounds
        }
        presentationWrappingView?.frame = frameOfPresentedViewInContainerView
    }
}

// MARK: - UIViewControllerAnimatedTransitioning

extension BottomSheetPresentationController: UIViewControllerAnimatedTransitioning {

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        if let context = transitionContext, context.isAnimated {
            return BottomSheetPresentationControllerConstants.transitionDuration
        }
        return 0
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {

        guard let fromViewController = transitionContext.viewController(forKey: .from),
            let toViewController = transitionContext.viewController(forKey: .to) else {

            return
        }

        let fromView = transitionContext.view(forKey: .from)
        let toView = transitionContext.view(forKey: .to)

        let containerView = transitionContext.containerView

        let isPresenting: Bool
        if fromViewController == presentingViewController {
            isPresenting = true
        } else {
            isPresenting = false
        }

        var fromViewFinalFrame = transitionContext.finalFrame(for: fromViewController)

        var toViewInitialFrame = transitionContext.initialFrame(for: toViewController)
        let toViewFinalFrame = transitionContext.finalFrame(for: toViewController)

        if let toView = toView {
            containerView.addSubview(toView)
        }

        if isPresenting == true {
            toViewInitialFrame.origin = CGPoint(x: containerView.bounds.minX, y: containerView.bounds.maxY)
            toViewInitialFrame.size = toViewFinalFrame.size
            toView?.frame = toViewInitialFrame
        } else {
            if let fromView = fromView {
                fromViewFinalFrame = fromView.frame.offsetBy(dx: 0, dy: fromView.frame.height)
            }
        }

        let duration = transitionDuration(using: transitionContext)

        UIView.animate(withDuration: duration,
                       animations: {

                        if isPresenting {
                            toView?.frame = toViewFinalFrame
                        } else {
                            fromView?.frame = fromViewFinalFrame
                        }
        }) { finished in
            let wasCancelled = transitionContext.transitionWasCancelled
            transitionContext.completeTransition(!wasCancelled)
        }
    }
}

// MARK: - UIViewControllerTransitioningDelegate

extension BottomSheetPresentationController: UIViewControllerTransitioningDelegate {

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {

        return self
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        return self
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        return self
    }
}

// MARK: - Objective-C support

@objc
extension BottomSheetPresentationController {
    func dimmingViewTapped() {
        presentingViewController.dismiss(animated: true)
    }
}
