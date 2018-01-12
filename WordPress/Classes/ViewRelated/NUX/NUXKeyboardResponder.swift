// The signin forms are centered, and then adjusted for the combined height of
// the status bar and navigation bar. -(20 + 44).
// If this value is changed be sure to update the storyboard for consistency.
let NUXKeyboardDefaultFormVerticalOffset: CGFloat = -64.0

/// A protocol and extension encapsulating common keyboard releated logic for
/// Signin controllers.
///
protocol NUXKeyboardResponder: class {
    var bottomContentConstraint: NSLayoutConstraint? {get}
    var verticalCenterConstraint: NSLayoutConstraint? {get}

    func signinFormVerticalOffset() -> CGFloat
    func registerForKeyboardEvents(keyboardWillShowAction: Selector, keyboardWillHideAction: Selector)
    func unregisterForKeyboardEvents()
    func adjustViewForKeyboard(_ visibleKeyboard: Bool)

    func keyboardWillShow(_ notification: Foundation.Notification)
    func keyboardWillHide(_ notification: Foundation.Notification)
}

extension NUXKeyboardResponder where Self: NUXViewController {

    /// Registeres the receiver for keyboard events using the passed selectors.
    /// We pass the selectors this way so we can encapsulate functionality in a
    /// Swift protocol extension and still play nice with Objective C code.
    ///
    /// - Parameters
    ///     - keyboardWillShowAction: A Selector to use for the UIKeyboardWillShowNotification observer.
    ///     - keyboardWillHideAction: A Selector to use for the UIKeyboardWillHideNotification observer.
    ///
    func registerForKeyboardEvents(keyboardWillShowAction: Selector, keyboardWillHideAction: Selector) {
        NotificationCenter.default.addObserver(self, selector: keyboardWillShowAction, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: keyboardWillHideAction, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }


    /// Unregisters the receiver from keyboard events.
    ///
    func unregisterForKeyboardEvents() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }


    /// Returns the vertical offset to apply to the sign in form.
    ///
    /// - Returns: NUXKeyboardDefaultFormVerticalOffset unless a conforming controller provides its own implementation.
    ///
    func signinFormVerticalOffset() -> CGFloat {
        return NUXKeyboardDefaultFormVerticalOffset
    }


    /// Adjusts constraint constants to adapt the view for a visible keyboard.
    ///
    /// - Parameter visibleKeyboard: Whether to configure for a visible keyboard or without a keyboard.
    ///
    func adjustViewForKeyboard(_ visibleKeyboard: Bool) {
        if visibleKeyboard && SigninEditingState.signinLastKeyboardHeightDelta > 0 {
            bottomContentConstraint?.constant = SigninEditingState.signinLastKeyboardHeightDelta
            verticalCenterConstraint?.constant = 0
        } else {
            bottomContentConstraint?.constant = 0
            verticalCenterConstraint?.constant = signinFormVerticalOffset()
        }
    }


    /// Process the passed NSNotification from a UIKeyboardWillShowNotification.
    ///
    /// - Parameter notification: the NSNotification object from a UIKeyboardWillShowNotification.
    ///
    func keyboardWillShow(_ notification: Foundation.Notification) {
        guard let keyboardInfo = keyboardFrameAndDurationFromNotification(notification) else {
            return
        }

        SigninEditingState.signinLastKeyboardHeightDelta = heightDeltaFromKeyboardFrame(keyboardInfo.keyboardFrame)
        SigninEditingState.signinEditingStateActive = true

        if bottomContentConstraint?.constant == SigninEditingState.signinLastKeyboardHeightDelta {
            return
        }

        adjustViewForKeyboard(true)
        UIView.animate(withDuration: keyboardInfo.animationDuration,
                       delay: 0,
                       options: .beginFromCurrentState,
                       animations: {
                        self.view.layoutIfNeeded()
        },
                       completion: nil)
    }


    /// Process the passed NSNotification from a UIKeyboardWillHideNotification.
    ///
    /// - Parameter notification: the NSNotification object from a UIKeyboardWillHideNotification.
    ///
    func keyboardWillHide(_ notification: Foundation.Notification) {
        guard let keyboardInfo = keyboardFrameAndDurationFromNotification(notification) else {
            return
        }

        SigninEditingState.signinEditingStateActive = false

        if bottomContentConstraint?.constant == 0 {
            return
        }

        adjustViewForKeyboard(false)
        UIView.animate(withDuration: keyboardInfo.animationDuration,
                       delay: 0,
                       options: .beginFromCurrentState,
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
    func keyboardFrameAndDurationFromNotification(_ notification: Foundation.Notification) -> (keyboardFrame: CGRect, animationDuration: Double)? {

        guard let userInfo = notification.userInfo,
            let frame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue
            else {
                return nil
        }
        return (keyboardFrame: frame, animationDuration: duration)
    }


    func heightDeltaFromKeyboardFrame(_ keyboardFrame: CGRect) -> CGFloat {
        // If an external keyboard is connected, the ending keyboard frame's maxY
        // will exceed the height of the view controller's view.
        // In these cases, just adjust the height by the amount of the keyboard visible.
        if keyboardFrame.maxY > UIScreen.main.bounds.size.height {
            return view.frame.height - keyboardFrame.minY
        }

        // If the safe area has a bottom height, subtract that.
        var bottomAdjust: CGFloat = 0
        if #available(iOS 11, *) {
            bottomAdjust = view.safeAreaInsets.bottom
        }
        return keyboardFrame.height - bottomAdjust
    }

}
