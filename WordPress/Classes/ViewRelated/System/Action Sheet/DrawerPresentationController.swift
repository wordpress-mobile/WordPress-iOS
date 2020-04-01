import UIKit

public enum DrawerPosition {
    case top
    case bottom
    case closed
}

public protocol DrawerPresentable: AnyObject {
    var initialHeight: CGFloat { get }
    var scrollableView: UIScrollView? { get }
    var allowsUserTransition: Bool { get }
    var allowsDragToDismiss: Bool { get }
}

typealias UIDrawerPresentable = DrawerPresentable & UIViewController

public extension DrawerPresentable where Self: UIViewController {
    //Default values
    var allowsUserTransition: Bool {
        return true
    }

    var initialHeight: CGFloat {
        return 0
    }

    var scrollableView: UIScrollView? {
        return nil
    }

    var allowsDragToDismiss: Bool {
        return true
    }

    // Helpers
    var presentedVC: DrawerPresentationController? {
        guard let navController = self.navigationController else {
            return presentationController as? DrawerPresentationController
        }

        return navController.presentationController as? DrawerPresentationController
    }
}

public class DrawerPresentationController: FancyAlertPresentationController {
    private enum Constants {
        static let transitionDuration: TimeInterval = 0.2
        static let defaultTopMargin: CGFloat = 20
        static let flickVelocity: CGFloat = 300
        static let bounceAmount: CGFloat = 0.01
    }

    override public var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = self.containerView else {
            return .zero
        }

        var frame = containerView.frame
        let y = bottomYPosition

        frame.origin.y = y

        return frame
    }

    public var position: DrawerPosition = .bottom

    public func transition(to position: DrawerPosition) {
        self.position = position

        if position == .closed {
            dismiss()
            return
        }

        var margin: CGFloat = 0

        switch position {
        case .top:
            margin = topYPosition

        case .bottom:
            margin = bottomYPosition

        default:
            margin = 0
        }

        setTopMargin(margin)
    }

    @objc func dismiss() {
        self.presentedViewController.dismiss(animated: true, completion: nil)
    }

    public override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()

        configureScrollViewInsets()
    }

    public override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)

        configureScrollViewInsets()
    }


    //MARK: - Internal Positions
    private var closedPosition: CGFloat {
        guard let presentedView = self.presentedView else {
            return 0
        }

        return presentedView.bounds.height
    }

    private var bottomYPosition: CGFloat {
        return calculatedTopMargin(for: presentableInitialHeight)
    }

    private var topYPosition: CGFloat {
        return Constants.defaultTopMargin + safeAreaInsets.top
    }


    //MARK: - Panning
    private lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        return UITapGestureRecognizer(target: self, action: #selector(self.dismiss))
    }()

    private lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        return UIPanGestureRecognizer(target: self, action: #selector(self.pan(_:)))
    }()

    var interactionController: UIPercentDrivenInteractiveTransition?

    override public func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()

        addGestures()
    }

    private var startPoint: CGPoint?

}

//MARK: - Dragging
private extension DrawerPresentationController {
    private func addGestures() {
        guard let presentedView = self.presentedView else { return }

        presentedView.addGestureRecognizer(self.panGestureRecognizer)
    }

    @objc func pan(_ gesture: UIPanGestureRecognizer) {
        guard let presentedView = self.presentedView else { return }

        let translation = gesture.translation(in: presentedView)
        let allowsUserTransition = presentableViewController?.allowsUserTransition ?? false
        let allowDragToDismiss = presentableViewController?.allowsDragToDismiss ?? true

        switch gesture.state {
        case .began:
            startPoint = presentedView.frame.origin

        case .changed:
            let startY = startPoint?.y ?? 0
            var yTranslation = translation.y

            if (!allowsUserTransition || !allowDragToDismiss) {
                let maxBounce: CGFloat = (startY * Constants.bounceAmount)

                if yTranslation < 0 {
                    yTranslation = max(yTranslation, maxBounce * -1)
                } else {
                    if !allowDragToDismiss {
                        yTranslation = min(yTranslation, maxBounce)
                    }
                }
            }

            self.setTopMargin((startY + yTranslation), animated: false)

        case .ended:
            /// Helper closure to prevent user transitions
            let transition:(DrawerPosition) -> () = { pos in

                if allowsUserTransition {
                    self.transition(to: pos)
                    return
                }

                if pos == .closed && allowDragToDismiss {
                    self.transition(to: pos)
                } else {
                    self.transition(to: self.position)
                }
            }

            let velocity = gesture.velocity(in: presentedView).y
            let startY = startPoint?.y ?? 0

            let currentPosition = (startY + translation.y)
            let position = closestPosition(for: currentPosition)

            // Determine how to handle flicking of the view
            if ((abs(velocity) - Constants.flickVelocity) > 0) {
                //Flick up
                if velocity < 0 {
                    transition(.top)
                }
                else {
                    if(position == .top){
                        transition(.bottom)
                    } else {
                        transition(.closed)
                    }
                }

                return
            }

            transition(position)

            startPoint = nil

        default:
            return
        }
    }

}

private extension UIScrollView {
    /**
     A flag to determine if a scroll view is scrolling
     */
    var isScrolling: Bool {
        return isDragging && !isDecelerating || isTracking
    }
}

//MARK: - Private: Helpers
private extension DrawerPresentationController {

    private func configureScrollViewInsets() {
        guard
            let scrollView = presentableViewController?.scrollableView,
            !scrollView.isScrolling,
            let presentedView = self.presentedView
            else { return }


        let bottom = presentingViewController.bottomLayoutGuide.length
        let margin = presentedView.frame.origin.y + bottom

        /**
         Disable vertical scroll indicator until we start to scroll
         to avoid visual bugs
         */
//        scrollView.showsVerticalScrollIndicator = false
//        scrollView.scrollIndicatorInsets = .zero
//
        scrollView.contentInset.bottom = margin
    }

    private var presentableViewController: DrawerPresentable? {
        return presentedViewController as? DrawerPresentable
    }

    private var presentableInitialHeight: CGFloat {
        guard let presentableVC = presentableViewController else {
            return 0
        }

        return presentableVC.initialHeight
    }

    private func calculatedTopMargin(for height: CGFloat) -> CGFloat {
        guard let containerView = self.containerView else {
            return 0
        }

        let bounds = containerView.bounds
        let margin = bounds.maxY - (safeAreaInsets.bottom + ((height > 0) ? height : (bounds.height * 0.5)))

        //Limit the max height
        return max(margin, safeAreaInsets.top)
    }

    private func setTopMargin(_ margin: CGFloat, animated: Bool = true) {
        guard let presentedView = self.presentedView else {
            return
        }

        var frame = presentedView.frame
        frame.origin.y = margin

        let animations = {
            presentedView.frame = frame

            self.configureScrollViewInsets()
        }

        if animated {
            animate(animations)
        } else {
            animations()
        }
    }

    private var safeAreaInsets: UIEdgeInsets {
        guard let rootViewController = self.rootViewController else {
            return .zero
        }

        return rootViewController.view.safeAreaInsets
    }

    func closestPosition(for yPosition: CGFloat) -> DrawerPosition {
        let positions = [closedPosition, bottomYPosition, topYPosition]
        let closestVal = positions.min(by: { abs(yPosition - $0) < abs(yPosition - $1) }) ?? yPosition

        var returnPosition: DrawerPosition = .closed

        if closestVal == topYPosition {
            returnPosition = .top
        } else if(closestVal == bottomYPosition) {
            returnPosition = .bottom
        }

        return returnPosition
    }

    private func animate(_ animations: @escaping () -> Void) {
        UIView.animate(withDuration: Constants.transitionDuration,
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0,
                       options: .curveEaseInOut,
                       animations: animations)
    }

    private var rootViewController: UIViewController? {
        return UIApplication.shared.keyWindow?.rootViewController
    }
}
