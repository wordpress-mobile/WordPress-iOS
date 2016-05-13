import UIKit

// The signin forms are centered, and then adjusted for the combined height of
// the status bar and navigation bar. -(20 + 44).
// If this value is changed be sure to update the storyboard for consistency.
let DefaultSigninFormVerticalOffset: CGFloat = -64.0

/// A protocol and extension encapsulating common keyboard releated logic for
/// Signin controllers.
///
protocol SigninKeyboardResponder: class
{
    var bottomContentConstraint: NSLayoutConstraint! {get}
    var verticalCenterConstraint: NSLayoutConstraint! {get}

    func signinFormVerticalOffset() -> CGFloat
    func registerForKeyboardEvents(keyboardWillShowAction keyboardWillShowAction: Selector, keyboardWillHideAction: Selector)
    func unregisterForKeyboardEvents()
    func adjustViewForKeyboard(visibleKeyboard: Bool)

    func keyboardWillShow(notification: NSNotification)
    func keyboardWillHide(notification: NSNotification)
}

extension SigninKeyboardResponder where Self: NUXAbstractViewController
{

    /// Registeres the receiver for keyboard events using the passed selectors.
    /// We pass the selectors this way so we can encapsulate functionality in a
    /// Swift protocol extension and still play nice with Objective C code.
    ///
    /// - Parameters
    ///     - keyboardWillShowAction: A Selector to use for the UIKeyboardWillShowNotification observer.
    ///     - keyboardWillHideAction: A Selector to use for the UIKeyboardWillHideNotification observer.
    ///
    func registerForKeyboardEvents(keyboardWillShowAction keyboardWillShowAction: Selector, keyboardWillHideAction: Selector) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: keyboardWillShowAction, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: keyboardWillHideAction, name: UIKeyboardWillHideNotification, object: nil)
    }


    /// Unregisters the receiver from keyboard events.
    ///
    func unregisterForKeyboardEvents() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }


    /// Returns the vertical offset to apply to the sign in form.
    ///
    /// - Returns: DefaultSigninFormVerticalOffset unless a conforming controller provides its own implementation.
    ///
    func signinFormVerticalOffset() -> CGFloat {
        return DefaultSigninFormVerticalOffset
    }


    /// Adjusts constraint constants to adapt the view for a visible keyboard.
    ///
    /// - Parameter visibleKeyboard: Whether to configure for a visible keyboard or without a keyboard.
    ///
    func adjustViewForKeyboard(visibleKeyboard: Bool) {
        if visibleKeyboard && SigninEditingState.signinLastKeyboardHeightDelta > 0 {
            bottomContentConstraint.constant = SigninEditingState.signinLastKeyboardHeightDelta
            verticalCenterConstraint.constant = 0
        } else {
            bottomContentConstraint.constant = 0
            verticalCenterConstraint.constant = signinFormVerticalOffset()
        }
    }


    /// Process the passed NSNotification from a UIKeyboardWillShowNotification.
    ///
    /// - Parameter notification: the NSNotification object from a UIKeyboardWillShowNotification.
    ///
    func keyboardWillShow(notification: NSNotification) {
        guard let keyboardInfo = keyboardFrameAndDurationFromNotification(notification) else {
            return
        }

        SigninEditingState.signinLastKeyboardHeightDelta = heightDeltaFromKeyboardFrame(keyboardInfo.keyboardFrame)
        SigninEditingState.signinEditingStateActive = true

        if bottomContentConstraint.constant == SigninEditingState.signinLastKeyboardHeightDelta {
            return
        }

        adjustViewForKeyboard(true)
        UIView.animateWithDuration(keyboardInfo.animationDuration,
                                   delay: 0,
                                   options: .BeginFromCurrentState,
                                   animations: {
                                        self.view.layoutIfNeeded()
                                    },
                                   completion: nil)
    }


    /// Process the passed NSNotification from a UIKeyboardWillHideNotification.
    ///
    /// - Parameter notification: the NSNotification object from a UIKeyboardWillHideNotification.
    ///
    func keyboardWillHide(notification: NSNotification) {
        guard let keyboardInfo = keyboardFrameAndDurationFromNotification(notification) else {
            return
        }

        SigninEditingState.signinEditingStateActive = false

        if bottomContentConstraint.constant == 0 {
            return
        }

        adjustViewForKeyboard(false)
        UIView.animateWithDuration(keyboardInfo.animationDuration,
                                   delay: 0,
                                   options: .BeginFromCurrentState,
                                   animations: {
                                        self.view.layoutIfNeeded()
                                    },
                                   completion: nil)
    }


    /// Retrieves the keyboard frame and the animation duration from a keyboard
    /// notificaiton.
    ///
    /// - Parameter notification: the NSNotification object from a keyboard notification.
    ///
    /// - Returns: An tupile optional containing the `keyboardFrame` and the `animationDuration`, or nil.
    ///
    func keyboardFrameAndDurationFromNotification(notification: NSNotification) -> (keyboardFrame: CGRect, animationDuration: Double)? {

        guard let userInfo = notification.userInfo,
            let frame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue(),
            let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue
            else {
                return nil
        }
        return (keyboardFrame: frame, animationDuration: duration)
    }


    func heightDeltaFromKeyboardFrame(keyboardFrame: CGRect) -> CGFloat {
        // If an external keyboard is connected, the ending keyboard frame's maxY
        // will exceed the height of the view controller's view.
        // There is no need to adjust the view in this case so just return 0.0.
        if (keyboardFrame.maxY > self.view.frame.height) {
            return 0.0
        }
        return keyboardFrame.height
    }

}
