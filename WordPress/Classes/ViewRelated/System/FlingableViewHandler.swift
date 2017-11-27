import UIKit

@objc
protocol FlingableViewHandlerDelegate {
    @objc optional func flingableViewHandlerDidBeginRecognizingGesture(_ handler: FlingableViewHandler)
    @objc optional func flingableViewHandlerDidEndRecognizingGesture(_ handler: FlingableViewHandler)
    @objc optional func flingableViewHandlerWasCancelled(_ handler: FlingableViewHandler)
}

class FlingableViewHandler: NSObject {
    /// The velocity at which the target view must be flung before it detaches.
    // Default value found through trial and error.
    @objc var escapeVelocity: CGFloat = 1500

    /// The amount of oscillation when the view snaps back to its original position
    /// Default is 0.8. 0.0 for no oscillation, 1.0 for max.
    @objc var snapDamping: CGFloat = 0.8

    /// Used to 'slow down' the fling velocity when the user releases their finger
    /// in horizontally or vertically compact views, otherwise the view feels
    /// like it's moving far too quickly.
    @objc var flingVelocityScaleFactorForCompactTraits: CGFloat = 5.0

    @objc var isActive = false {
        didSet {
            panGestureRecognizer.isEnabled = isActive
        }
    }

    @objc var delegate: FlingableViewHandlerDelegate?

    fileprivate let animator: UIDynamicAnimator
    fileprivate var attachmentBehavior: UIAttachmentBehavior!
    fileprivate var panGestureRecognizer: UIPanGestureRecognizer!

    // Used to restore the target view to its original position if the gesture is cancelled
    fileprivate var initialCenter: CGPoint? = nil

    /// - parameter targetView: The view that can be flung.
    @objc init(targetView: UIView) {
        precondition(targetView.superview != nil, "The target view must have a superview!")

        animator = UIDynamicAnimator(referenceView: targetView.superview!)

        super.init()

        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        targetView.addGestureRecognizer(panGestureRecognizer)
        isActive = true
    }

    @objc
    fileprivate func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        guard isActive else { return }
        guard let view = recognizer.view,
              let referenceView = animator.referenceView else { return }

        switch recognizer.state {
        case .began:
            delegate?.flingableViewHandlerDidBeginRecognizingGesture?(self)

            animator.removeAllBehaviors()

            // Keep track of the view's initial position so we can restore it later
            initialCenter = view.center

            attachmentBehavior = makeAttachmentBehaviorForRecognizer(recognizer, inView: view)
            animator.addBehavior(attachmentBehavior)
            break
        case .changed:
            let anchor = recognizer.location(ofTouch: 0, in: referenceView)
            attachmentBehavior.anchorPoint = anchor
            break
        case .ended, .cancelled:
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

    fileprivate func makeAttachmentBehaviorForRecognizer(_ recognizer: UIGestureRecognizer, inView view: UIView) -> UIAttachmentBehavior {
        let location = recognizer.location(in: view)

        let (centerX, centerY) = (round(view.bounds.width / 2.0), round(view.bounds.height / 2.0))
        let offset = UIOffset(horizontal: location.x - centerX, vertical: location.y - centerY)

        let anchor = recognizer.location(in: animator.referenceView)

        return UIAttachmentBehavior(item: view,
                                    offsetFromCenter: offset,
                                    attachedToAnchor: anchor)
    }

    fileprivate func makeSnapBehaviorForView(_ view: UIView) -> UISnapBehavior {
        let snap = UISnapBehavior(item: view, snapTo: initialCenter!)
        snap.damping = snapDamping

        return snap
    }

    fileprivate func makePushBehaviorForRecognizer(_ recognizer: UIPanGestureRecognizer, inView view: UIView) -> UIPushBehavior {
        let velocity = recognizer.velocity(in: view)
        let magnitude = recognizer.magnitudeInView(view)

        let pushBehavior = UIPushBehavior(items: [view], mode: .instantaneous)

        // Push in the same direction as the user was moving their touch
        let pushDirection = CGVector(dx: velocity.x, dy: velocity.y)
        pushBehavior.pushDirection = pushDirection

        // Scale down the magnitude for smaller display sizes
        let horizontallyCompactTraits = UITraitCollection(horizontalSizeClass: .compact)
        let verticallyCompactTraits = UITraitCollection(verticalSizeClass: .compact)

        if view.traitCollection.containsTraits(in: horizontallyCompactTraits) ||
            view.traitCollection.containsTraits(in: verticallyCompactTraits) {
            pushBehavior.magnitude = magnitude / flingVelocityScaleFactorForCompactTraits
        } else {
            pushBehavior.magnitude = magnitude
        }

        // Apply the force at the same offset as the user's touch from the view's center
        let referenceView = animator.referenceView
        let location = recognizer.location(in: referenceView)
        let center = view.center
        let offset = UIOffset(horizontal: location.x - center.x, vertical: location.y - center.y)
        pushBehavior.setTargetOffsetFromCenter(offset, for: view)

        // Check for the view leaving the screen
        pushBehavior.action = { [weak self] in
            guard let strongSelf = self,
                  let referenceView = referenceView else { return }

            if !view.frame.intersects(referenceView.bounds) {
                strongSelf.animator.removeAllBehaviors()
                view.removeFromSuperview()

                strongSelf.delegate?.flingableViewHandlerDidEndRecognizingGesture?(strongSelf)
            }
        }

        return pushBehavior
    }
}

private extension UIPanGestureRecognizer {
    func magnitudeInView(_ view: UIView) -> CGFloat {
        let velocity = self.velocity(in: view)
        return sqrt((velocity.x * velocity.x) + (velocity.y * velocity.y))
    }
}
