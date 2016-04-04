import UIKit

///
///
protocol SigninKeyboardResponder: class
{
    var bottomContentConstraint: NSLayoutConstraint! {get}

    func keyboardWillShow(notification: NSNotification)
    func keyboardWillHide(notification: NSNotification)

    func registerForKeyboardEvents(keyboardWillShowAction: Selector, keyboardWillHideAction: Selector)
    func unregisterForKeyboardEvents()
}

extension SigninKeyboardResponder where Self: NUXAbstractViewController
{

    ///
    ///
    func registerForKeyboardEvents(keyboardWillShowAction: Selector, keyboardWillHideAction: Selector) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: keyboardWillShowAction, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: keyboardWillHideAction, name: UIKeyboardWillHideNotification, object: nil)
    }


    ///
    ///
    func unregisterForKeyboardEvents() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }


    ///
    ///
    func keyboardWillShow(notification: NSNotification) {
        guard let keyboardInfo = keyboardFrameAndDurationFromNotification(notification) else {
            return
        }

        SigninEditingState.signinLastKeyboardHeight = keyboardInfo.keyboardFrame.height
        SigninEditingState.signinEditingStateActive = true

        bottomContentConstraint.constant = keyboardInfo.keyboardFrame.height
        UIView.animateWithDuration(keyboardInfo.animationDuration,
                                   delay: 0,
                                   options: .BeginFromCurrentState,
                                   animations: { 
                                        self.view.layoutIfNeeded()
                                    },
                                   completion: nil)
    }


    ///
    ///
    func keyboardWillHide(notification: NSNotification) {
        guard let keyboardInfo = keyboardFrameAndDurationFromNotification(notification) else {
            return
        }

        SigninEditingState.signinEditingStateActive = false

        bottomContentConstraint.constant = 0
        UIView.animateWithDuration(keyboardInfo.animationDuration,
                                   delay: 0,
                                   options: .BeginFromCurrentState,
                                   animations: {
                                        self.view.layoutIfNeeded()
                                    },
                                   completion: nil)
    }


    ///
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

}
