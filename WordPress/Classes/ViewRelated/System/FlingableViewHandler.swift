import UIKit

@objc
protocol FlingableViewHandlerDelegate {
    optional func flingableViewHandlerDidBeginRecognizingGesture(handler: FlingableViewHandler)
    optional func flingableViewHandlerDidEndRecognizingGesture(handler: FlingableViewHandler)
    optional func flingableViewHandlerWasCancelled(handler: FlingableViewHandler)
}

class FlingableViewHandler: NSObject {
    /// The velocity at which the target view must be flung before it detaches.
    // Default value found through trial and error.
    var escapeVelocity: CGFloat = 1500

    /// The amount of oscillation when the view snaps back to its original position
    /// Default is 0.8. 0.0 for no oscillation, 1.0 for max.
    var snapDamping: CGFloat = 0.8

    /// Used to 'slow down' the fling velocity when the user releases their finger
    /// in horizontally or vertically compact views, otherwise the view feels
    /// like it's moving far too quickly.
    var flingVelocityScaleFactorForCompactTraits: CGFloat = 5.0

    var isActive = false {
        didSet {
            panGestureRecognizer.enabled = isActive
        }
    }

    var delegate: FlingableViewHandlerDelegate?

    private let animator: UIDynamicAnimator
    private var attachmentBehavior: UIAttachmentBehavior!
    private var panGestureRecognizer: UIPanGestureRecognizer!

    // Used to restore the target view to its original position if the gesture is cancelled
    private var initialCenter: CGPoint? = nil

    /// - parameter targetView: The view that can be flung.
    init(targetView: UIView) {
        precondition(targetView.superview != nil, "The target view must have a superview!")

        animator = UIDynamicAnimator(referenceView: targetView.superview!)

        super.init()

        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        targetView.addGestureRecognizer(panGestureRecognizer)
        isActive = true
    }

    @objc
    private func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        guard isActive else { return }
        guard let view = recognizer.view,
              let referenceView = animator.referenceView else { return }

        switch recognizer.state {
        case .Began:
            delegate?.flingableViewHandlerDidBeginRecognizingGesture?(self)

            animator.removeAllBehaviors()

            // Keep track of the view's initial position so we can restore it later
            initialCenter = view.center

            attachmentBehavior = makeAttachmentBehaviorForRecognizer(recognizer, inView: view)
            animator.addBehavior(attachmentBehavior)
            break
        case .Changed:
            let anchor = recognizer.locationInView(referenceView)
            attachmentBehavior.anchorPoint = anchor
            break
        case .Ended, .Cancelled:
            animator.removeAllBehaviors()

            let magnitude = recognizer.magnitudeInView(referenceView)
            if magnitude < escapeVelocity {
                animator.addBehavior(makeSnapBehaviorForView(view))

                delegate?.flingableViewHandlerWasCancelled?(self)

                return
            }

            let pushBehavior = makePushBehaviorForRecognizer(recognizer, inView: view)
            animator.addBehavior(pushBehavior)
            break
        default:
            break
        }
    }

    private func makeAttachmentBehaviorForRecognizer(recognizer: UIGestureRecognizer, inView view: UIView) -> UIAttachmentBehavior {
        let location = recognizer.locationInView(view)

        let (centerX, centerY) = (view.bounds.width / 2.0, view.bounds.height / 2.0)
        let offset = UIOffset(horizontal: location.x - centerX, vertical: location.y - centerY)

        let anchor = recognizer.locationInView(animator.referenceView)

        return UIAttachmentBehavior(item: view,
                                    offsetFromCenter: offset,
                                    attachedToAnchor: anchor)
    }

    private func makeSnapBehaviorForView(view: UIView) -> UISnapBehavior {
        let snap = UISnapBehavior(item: view, snapToPoint: initialCenter!)
        snap.damping = snapDamping

        return snap
    }

    private func makePushBehaviorForRecognizer(recognizer: UIPanGestureRecognizer, inView view: UIView) -> UIPushBehavior {
        let velocity = recognizer.velocityInView(view)
        let magnitude = recognizer.magnitudeInView(view)

        let pushBehavior = UIPushBehavior(items: [view], mode: .Instantaneous)

        // Push in the same direction as the user was moving their touch
        let pushDirection = CGVector(dx: velocity.x, dy: velocity.y)
        pushBehavior.pushDirection = pushDirection

        // Scale down the magnitude for smaller display sizes
        let horizontallyCompactTraits = UITraitCollection(horizontalSizeClass: .Compact)
        let verticallyCompactTraits = UITraitCollection(verticalSizeClass: .Compact)

        if view.traitCollection.containsTraitsInCollection(horizontallyCompactTraits) ||
            view.traitCollection.containsTraitsInCollection(verticallyCompactTraits) {
            pushBehavior.magnitude = magnitude / flingVelocityScaleFactorForCompactTraits
        } else {
            pushBehavior.magnitude = magnitude
        }

        // Apply the force at the same offset as the user's touch from the view's center
        let referenceView = animator.referenceView
        let location = recognizer.locationInView(referenceView)
        let center = view.center
        let offset = UIOffset(horizontal: location.x - center.x, vertical: location.y - center.y)
        pushBehavior.setTargetOffsetFromCenter(offset , forItem: view)

        // Check for the view leaving the screen
        pushBehavior.action = { [weak self] in
            guard let strongSelf = self,
                  let referenceView = referenceView else { return }

            if !CGRectIntersectsRect(view.frame, referenceView.bounds) {
                strongSelf.animator.removeAllBehaviors()
                view.removeFromSuperview()

                strongSelf.delegate?.flingableViewHandlerDidEndRecognizingGesture?(strongSelf)
            }
        }

        return pushBehavior
    }
}

private extension UIPanGestureRecognizer {
    func magnitudeInView(view: UIView) -> CGFloat {
        let velocity = velocityInView(view)
        return sqrt((velocity.x * velocity.x) + (velocity.y * velocity.y))
    }
}
