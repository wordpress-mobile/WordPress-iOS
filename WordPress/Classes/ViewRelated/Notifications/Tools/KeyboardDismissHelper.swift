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
    var dismissableControl: UIView?

    /// Reference to the bottom layout constraint
    ///
    var bottomLayoutConstraint: NSLayoutConstraint

    /// Closure to be executed whenever the Keyboard will be Hidden
    ///
    var onWillHide: (() -> Void)?

    /// Closure to be executed whenever the Keyboard was hidden
    ///
    var onDidHide: (() -> Void)?

    /// Closure to be executed whenever the Keyboard will be Shown
    ///
    var onWillShow: (() -> Void)?

    /// Closure to be executed whenever the Keyboard was Shown
    ///
    var onDidShow: (() -> Void)?

    /// Closure to be executed whenever the Keyboard *will* change its frame
    ///
    var onWillChangeFrame: (() -> Void)?

    /// Closure to be executed whenever the Keyboard *did* change its frame
    ///
    var onDidChangeFrame: (() -> Void)?



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

    /// Indicates whether the keyboard is visible or not
    ///
    fileprivate var isKeyboardVisible = false {
        didSet {
            // Reset any current Drag OP on change
            trackingDragOperation = false
        }
    }

    /// Indicates whether an Interactive Drag OP is being processed
    ///
    fileprivate var trackingDragOperation = false


    /// Deinitializer
    ///
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Designated initializer
    ///
    /// -   Parameter scrollView: View that contains everything
    ///
    init(parentView: UIView, scrollView: UIScrollView, dismissableControl: UIView, bottomLayoutConstraint: NSLayoutConstraint) {
        self.parentView = parentView
        self.scrollView = scrollView
        self.dismissableControl = dismissableControl
        self.bottomLayoutConstraint = bottomLayoutConstraint

        scrollView.keyboardDismissMode = .interactive
    }


    /// Initializes the Keyboard Event Listeners
    ///
    func startListeningToKeyboardNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        nc.addObserver(self, selector: #selector(keyboardDidShow), name: .UIKeyboardDidShow, object: nil)
        nc.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
        nc.addObserver(self, selector: #selector(keyboardDidHide), name: .UIKeyboardDidHide, object: nil)
        nc.addObserver(self, selector: #selector(keyboardWillChangeFrame), name: .UIKeyboardWillChangeFrame, object: nil)
        nc.addObserver(self, selector: #selector(keyboardDidChangeFrame), name: .UIKeyboardDidChangeFrame, object: nil)

    }

    /// Removes all of the Keyboard Event Listeners
    ///
    func stopListeningToKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self)
    }



    /// ScrollView willBeginDragging Event
    ///
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard let dismissableControl = dismissableControl, isKeyboardVisible == true else {
            return
        }

        initialControlPositionY = dismissableControl.frame.maxY
        initialBottomConstraint = bottomLayoutConstraint.constant
        trackingDragOperation = true
    }

    /// ScrollView didScroll Event
    ///
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
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

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint) {
        trackingDragOperation = false
    }


    // MARK: - Notification Helpers
    func keyboardWillShow(_ note: Foundation.Notification) {
        isKeyboardVisible = true
        refreshBottomInsetIfNeeded(note)
        onWillShow?()
    }

    func keyboardDidShow(_ note: Foundation.Notification) {
        refreshBottomInsetIfNeeded(note)
        onDidShow?()
    }

    func keyboardWillHide(_ note: Foundation.Notification) {
        isKeyboardVisible = false
        refreshBottomInsetIfNeeded(note, isHideEvent: true)
        onWillHide?()
    }

    func keyboardDidHide(_ note: Foundation.Notification) {
        refreshBottomInsetIfNeeded(note, isHideEvent: true)
        onDidHide?()
    }

    func keyboardWillChangeFrame(_ note: Foundation.Notification) {
        onWillChangeFrame?()
    }

    func keyboardDidChangeFrame(_ note: Foundation.Notification) {
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
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationCurve(curve)
        UIView.setAnimationDuration(duration)

        bottomLayoutConstraint.constant = newBottomInset
        parentView.layoutIfNeeded()

        UIView.commitAnimations()
    }

    fileprivate func bottomInsetFromKeyboardNote(_ note: Foundation.Notification) -> CGFloat {
        let wrappedRect = note.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue
        let keyboardRect = wrappedRect?.cgRectValue ?? CGRect.zero
        let relativeRect = parentView.convert(keyboardRect, from: nil)
        let bottomInset = max(relativeRect.height - relativeRect.maxY + parentView.frame.height, 0)

        return bottomInset
    }

    fileprivate func durationFromKeyboardNote(_ note: Foundation.Notification) -> TimeInterval {
        guard let duration = note.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval else {
            return TimeInterval(0)
        }

        return duration
    }

    fileprivate func curveFromKeyboardNote(_ note: Foundation.Notification) -> UIViewAnimationCurve {
        guard let rawCurve = note.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? Int,
            let curve = UIViewAnimationCurve(rawValue: rawCurve) else {
            return .easeInOut
        }

        return curve
    }
}
