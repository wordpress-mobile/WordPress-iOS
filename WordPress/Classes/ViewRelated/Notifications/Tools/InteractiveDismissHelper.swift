import Foundation
import UIKit


/// Helper meant to aid in the InteractiveDismiss process.
///
/// Why this class exists:
/// -   UIScrollView/UITableView comes with a handy `UIScrollViewKeyboardDismissModeInteractive` keyboardDismissMode.
/// -   During an interactive dismiss, no keyboard repositioning notification gets posted. Ever.
/// -   Meant initially to be used along with ReplyTextView
///
/// Usage:
/// -   Initialize it with a reference to the container + bottom constraint
/// -   Set the dismissableControl reference
/// -   Forward the scrollView willBegin/didScroll events
///
@objc class InteractiveDismissHelper: NSObject
{
    /// Reference to the control to-be-dismissed
    ///
    var dismissableControl: UIView?

    /// Reference to the container view
    ///
    private var parentView: UIView

    /// Reference to the bottom layout constraint
    ///
    private var bottomLayoutConstraint: NSLayoutConstraint

    /// State of the BottomLayout Constraint, at the beginning of a drag OP
    ///
    private var initialBottomConstraint = CGFloat(0)

    /// State of the dismissable control's frame, at the beginning of a drag OP
    ///
    private var initialControlPositionY = CGFloat(0)


    /// Designated initializer
    ///
    /// -   Parameters:
    ///     -   parentView: View that contains everything
    ///     -   bottomLayoutConstraint: Constraint that will be updated during a drag OP
    ///
    init(parentView: UIView, bottomLayoutConstraint: NSLayoutConstraint) {
        self.parentView = parentView
        self.bottomLayoutConstraint = bottomLayoutConstraint
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
}
