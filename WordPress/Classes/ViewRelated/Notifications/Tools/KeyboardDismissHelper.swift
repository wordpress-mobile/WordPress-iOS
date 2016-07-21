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
@objc class KeyboardDismissHelper: NSObject
{
    /// Reference to the control to-be-dismissed
    ///
    var dismissableControl: UIView?

    /// Reference to the bottom layout constraint
    ///
    var bottomLayoutConstraint: NSLayoutConstraint

    /// Closure to be executed whenever the Keyboard will be Hidden
    ///
    var onWillHide: (Void -> ())?

    /// Closure to be executed whenever the Keyboard was hidden
    ///
    var onDidHide: (Void -> ())?

    /// Closure to be executed whenever the Keyboard will be Shown
    ///
    var onWillShow: (Void -> ())?

    /// Closure to be executed whenever the Keyboard was Shown
    ///
    var onDidShow: (Void -> ())?


    /// Reference to the container view
    ///
    private var scrollView: UIScrollView

    /// Returns the scrollView's Parent View. If nil, will fall back to the scrollView itself
    ///
    private var parentView: UIView

    /// State of the BottomLayout Constraint, at the beginning of a drag OP
    ///
    private var initialBottomConstraint = CGFloat(0)

    /// State of the dismissable control's frame, at the beginning of a drag OP
    ///
    private var initialControlPositionY = CGFloat(0)

    /// Indicates whether the keyboard is visible or not
    ///
    private var isKeyboardVisible = false

    /// Indicates whether an Interactive Drag OP is being processed
    ///
    private var trackingDragOperation = false


    /// Deinitializer
    ///
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
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

        scrollView.keyboardDismissMode = .Interactive
    }


    /// Initializes the Keyboard Event Listeners
    ///
    func startListeningToKeyboardNotifications() {
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: #selector(keyboardWillShow), name: UIKeyboardWillShowNotification, object: nil)
        nc.addObserver(self, selector: #selector(keyboardDidShow), name: UIKeyboardDidShowNotification, object: nil)
        nc.addObserver(self, selector: #selector(keyboardWillHide), name: UIKeyboardWillHideNotification, object: nil)
        nc.addObserver(self, selector: #selector(keyboardDidHide), name: UIKeyboardDidHideNotification, object: nil)

    }

    /// Removes all of the Keyboard Event Listeners
    ///
    func stopListeningToKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }



    /// ScrollView willBeginDragging Event
    ///
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        guard let dismissableControl = dismissableControl where isKeyboardVisible == true else {
            return
        }

        initialControlPositionY = dismissableControl.frame.maxY
        initialBottomConstraint = bottomLayoutConstraint.constant
        trackingDragOperation = true
    }

    /// ScrollView didScroll Event
    ///
    func scrollViewDidScroll(scrollView: UIScrollView) {
        guard trackingDragOperation == true else {
            return
        }

        let location = scrollView.panGestureRecognizer.locationInView(parentView)
        let delta = location.y - initialControlPositionY
        let newConstant = min(max(initialBottomConstraint - delta, 0), initialBottomConstraint)

        guard newConstant != bottomLayoutConstraint.constant else {
            return
        }

        bottomLayoutConstraint.constant = newConstant
        parentView.layoutIfNeeded()
    }

    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        trackingDragOperation = false
    }


    // MARK: - Notification Helpers
    func keyboardWillShow(note: NSNotification) {
        handleKeyboardFrameChange(note)
        onWillShow?()
    }

    func keyboardDidShow(note: NSNotification) {
        isKeyboardVisible = true
        handleKeyboardFrameChange(note)
        onDidShow?()
    }

    func keyboardWillHide(note: NSNotification) {
        isKeyboardVisible = false
        handleKeyboardFrameChange(note)
        onWillHide?()
    }

    func keyboardDidHide(note: NSNotification) {
        handleKeyboardFrameChange(note)
        onDidHide?()
    }


    // MARK: - Private Helpers

    private func handleKeyboardFrameChange(note: NSNotification) {
        guard let kbRect = note.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue,
            let duration = note.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSTimeInterval,
            let rawCurve = note.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? Int,
            let curve = UIViewAnimationCurve(rawValue: rawCurve) else
        {
            return
        }

        // Bottom Inset: Consider the tab bar!
        let convertedKeyboardRect = parentView.convertRect(kbRect.CGRectValue(), fromView: nil)
        let bottomInset = max(convertedKeyboardRect.height - convertedKeyboardRect.maxY + parentView.frame.height, 0)

        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationCurve(curve)
        UIView.setAnimationDuration(duration)

        bottomLayoutConstraint.constant = max(bottomInset, 0)
        parentView.layoutIfNeeded()

        UIView.commitAnimations()
    }
}
