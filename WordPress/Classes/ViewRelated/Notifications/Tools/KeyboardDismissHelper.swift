import Foundation
import UIKit


/// Helper meant to aid in the InteractiveDismiss process.
///
/// Why this class exists:
/// -   UIScrollView comes with a handy `UIScrollViewKeyboardDismissModeInteractive` keyboardDismissMode.
/// -   During an interactive dismiss, no keyboard repositioning notification gets posted. Ever.
/// -   Meant initially to be used along with ReplyTextView
///
/// Usage:
/// -   Initialize it with a reference to the scrollView + bottom constraint + dismissableControl
/// -   Forward the scrollView willBegin/didScroll events
///
@objc class KeyboardDismissHelper: NSObject {
    /// Reference to the control to-be-dismissed
    ///
    @objc var dismissableControl: UIView?

    /// Reference to the bottom layout constraint
    ///
    @objc var bottomLayoutConstraint: NSLayoutConstraint

    /// Closure to be executed whenever the Keyboard will be Hidden
    ///
    @objc var onWillHide: (() -> Void)?

    /// Closure to be executed whenever the Keyboard was hidden
    ///
    @objc var onDidHide: (() -> Void)?

    /// Closure to be executed whenever the Keyboard will be Shown
    ///
    @objc var onWillShow: (() -> Void)?

    /// Closure to be executed whenever the Keyboard was Shown
    ///
    @objc var onDidShow: (() -> Void)?

    /// Closure to be executed whenever the Keyboard *will* change its frame
    ///
    @objc var onWillChangeFrame: (() -> Void)?

    /// Closure to be executed whenever the Keyboard *did* change its frame
    ///
    @objc var onDidChangeFrame: (() -> Void)?

    /// Indicates whether the keyboard is visible or not
    ///
    @objc var isKeyboardVisible = false {
        didSet {
            // Reset any current Drag OP on change
            trackingDragOperation = false
        }
    }

    /// Reference to the container view
    ///
    fileprivate var scrollView: UIScrollView

    /// Returns the scrollView's Parent View. If nil, will fall back to the scrollView itself
    ///
    fileprivate var parentView: UIView

    /// State of the BottomLayout Constraint, at the beginning of a drag OP
    ///
    fileprivate var initialBottomConstraint = CGFloat(0)

    /// State of the dismissable control's frame, at the beginning of a drag OP
    ///
    fileprivate var initialControlPositionY = CGFloat(0)

    /// Indicates whether an Interactive Drag OP is being processed
    ///
    fileprivate var trackingDragOperation = false

    /// Designated initializer
    ///
    /// -   Parameter scrollView: View that contains everything
    ///
    @objc init(parentView: UIView, scrollView: UIScrollView, dismissableControl: UIView, bottomLayoutConstraint: NSLayoutConstraint) {
        self.parentView = parentView
        self.scrollView = scrollView
        self.dismissableControl = dismissableControl
        self.bottomLayoutConstraint = bottomLayoutConstraint

        scrollView.keyboardDismissMode = .interactive
    }


    /// Initializes the Keyboard Event Listeners
    ///
    @objc func startListeningToKeyboardNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(keyboardWillShow),
                       name: UIResponder.keyboardWillShowNotification,
                       object: nil)
        nc.addObserver(self,
                       selector: #selector(keyboardDidShow),
                       name: UIResponder.keyboardDidShowNotification,
                       object: nil)
        nc.addObserver(self,
                       selector: #selector(keyboardWillHide),
                       name: UIResponder.keyboardWillHideNotification,
                       object: nil)
        nc.addObserver(self,
                       selector: #selector(keyboardDidHide),
                       name: UIResponder.keyboardDidHideNotification,
                       object: nil)
        nc.addObserver(self,
                       selector: #selector(keyboardWillChangeFrame),
                       name: UIResponder.keyboardWillChangeFrameNotification,
                       object: nil)
        nc.addObserver(self,
                       selector: #selector(keyboardDidChangeFrame),
                       name: UIResponder.keyboardDidChangeFrameNotification,
                       object: nil)

    }

    /// Removes all of the Keyboard Event Listeners
    ///
    @objc func stopListeningToKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    /// ScrollView willBeginDragging Event
    ///
    @objc func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard let dismissableControl = dismissableControl, isKeyboardVisible == true else {
            return
        }

        initialControlPositionY = dismissableControl.frame.maxY
        initialBottomConstraint = bottomLayoutConstraint.constant
        trackingDragOperation = true
    }

    /// ScrollView didScroll Event
    ///
    @objc func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard trackingDragOperation == true else {
            return
        }

        let location = scrollView.panGestureRecognizer.location(in: parentView)
        let delta = location.y - initialControlPositionY
        let newConstant = min(max(initialBottomConstraint - delta, 0), initialBottomConstraint)

        guard newConstant != bottomLayoutConstraint.constant else {
            return
        }

        let previousContentOffset = scrollView.contentOffset

        bottomLayoutConstraint.constant = newConstant
        parentView.layoutIfNeeded()

        // Make sure the Scroll View's offset does not get reset!
        scrollView.contentOffset = previousContentOffset
    }

    @objc func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint) {
        trackingDragOperation = false
    }


    // MARK: - Notification Helpers
    @objc func keyboardWillShow(_ note: Foundation.Notification) {
        isKeyboardVisible = true
        refreshBottomInsetIfNeeded(note)
        onWillShow?()
    }

    @objc func keyboardDidShow(_ note: Foundation.Notification) {
        refreshBottomInsetIfNeeded(note)
        onDidShow?()
    }

    @objc func keyboardWillHide(_ note: Foundation.Notification) {
        isKeyboardVisible = false
        refreshBottomInsetIfNeeded(note, isHideEvent: true)
        onWillHide?()
    }

    @objc func keyboardDidHide(_ note: Foundation.Notification) {
        refreshBottomInsetIfNeeded(note, isHideEvent: true)
        onDidHide?()
    }

    @objc func keyboardWillChangeFrame(_ note: Foundation.Notification) {
        onWillChangeFrame?()
    }

    @objc func keyboardDidChangeFrame(_ note: Foundation.Notification) {
        onDidChangeFrame?()
    }


    // MARK: - Private Helpers

    fileprivate func refreshBottomInsetIfNeeded(_ note: Foundation.Notification, isHideEvent: Bool = false) {
        // Parse the Notification: We'll enforce a Zero Padding for Hide Events
        let duration = durationFromKeyboardNote(note)
        let curve = curveFromKeyboardNote(note)
        let newBottomInset = isHideEvent ? CGFloat(0) : bottomInsetFromKeyboardNote(note)

        // Don't Overwork!
        guard newBottomInset != bottomLayoutConstraint.constant else {
            return
        }

        // Proceed Animating
        let options = UIView.AnimationOptions(rawValue: UInt(curve.rawValue))
        UIView.animate(withDuration: duration, delay: 0, options: options) { [weak self] in
            self?.bottomLayoutConstraint.constant = newBottomInset
            self?.parentView.layoutIfNeeded()
        } completion: { _ in }

    }

    fileprivate func bottomInsetFromKeyboardNote(_ note: Foundation.Notification) -> CGFloat {
        let wrappedRect = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        let keyboardRect = wrappedRect?.cgRectValue ?? CGRect.zero
        let relativeRect = parentView.convert(keyboardRect, from: nil)
        let bottomInset = max(relativeRect.height - relativeRect.maxY + parentView.frame.height, 0)

        return bottomInset
    }

    fileprivate func durationFromKeyboardNote(_ note: Foundation.Notification) -> TimeInterval {
        guard let duration = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {
            return TimeInterval(0)
        }

        return duration
    }

    fileprivate func curveFromKeyboardNote(_ note: Foundation.Notification) -> UIView.AnimationCurve {
        guard let rawCurve = note.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int,
            let curve = UIView.AnimationCurve(rawValue: rawCurve) else {
            return .easeInOut
        }

        return curve
    }
}
