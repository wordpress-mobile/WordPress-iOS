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
        // Listening to UIKeyboardWillChangeFrameNotification is not enough. There are few corner cases in which
        // willChangeFrame doesn't get fired, and the keyboard either dismisses, or gets repositioned.
        //
        let nc = NSNotificationCenter.defaultCenter()
        let notifications = [UIKeyboardWillChangeFrameNotification, UIKeyboardDidChangeFrameNotification, UIKeyboardWillHideNotification]

        for name in notifications {
            nc.addObserver(self, selector: #selector(handleKeyboardFrameChange), name: name, object: nil)
        }
    }

    /// Removes all of the Keyboard Event Listeners
    ///
    func stopListeningToKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }



    /// ScrollView willBeginDragging Event
    ///
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        guard let dismissableControl = dismissableControl else {
            return
        }

        initialControlPositionY = dismissableControl.frame.maxY
        initialBottomConstraint = bottomLayoutConstraint.constant
    }

    /// ScrollView didScroll Event
    ///
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let location = scrollView.panGestureRecognizer.locationInView(parentView)
        let delta = location.y - initialControlPositionY
        let newConstant = min(max(initialBottomConstraint - delta, 0), initialBottomConstraint)

        guard newConstant != bottomLayoutConstraint.constant && dismissableControl != nil else {
            return
        }

        bottomLayoutConstraint.constant = newConstant
        parentView.layoutIfNeeded()
    }



    // MARK: - Notification Helpers

    func handleKeyboardFrameChange(note: NSNotification) {
        guard let kbRect = note.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue,
            let duration = note.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSTimeInterval,
            let rawCurve = note.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? Int,
            let curve = UIViewAnimationCurve(rawValue: rawCurve) else
        {
            return
        }

        // Bottom Inset: Consider the tab bar!
        let convertedKeyboardRect = parentView.convertRect(kbRect.CGRectValue(), fromView: nil)
        let bottomInset = convertedKeyboardRect.height - convertedKeyboardRect.maxY + parentView.frame.height

        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationCurve(curve)
        UIView.setAnimationDuration(duration)

        bottomLayoutConstraint.constant = max(bottomInset, 0)
        parentView.layoutIfNeeded()

        UIView.commitAnimations()
    }
}
