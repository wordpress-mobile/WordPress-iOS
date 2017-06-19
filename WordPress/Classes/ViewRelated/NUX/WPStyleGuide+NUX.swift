import WordPressShared

extension WPStyleGuide {

    /// Common view style for signin view controllers.
    ///
    /// - Parameters:
    ///     - view: The view to style.
    ///
    class func configureColorsForSigninView(_ view: UIView) {
        view.backgroundColor = wordPressBlue()
    }


    ///
    ///
    class func configureOnePasswordButtonForTextfield(_ textField: WPWalkthroughTextField, target: NSObject, selector: Selector) {
        if !OnePasswordFacade().isOnePasswordEnabled() {
            return
        }

        let onePasswordButton = UIButton(type: .custom)
        onePasswordButton.setImage(UIImage(named: "onepassword-wp-button"), for: UIControlState())
        onePasswordButton.sizeToFit()

        textField.rightView = onePasswordButton
        textField.rightViewPadding = UIOffset(horizontal: 9.0, vertical: 0.0)
        textField.rightViewMode = .always

        onePasswordButton.addTarget(target, action: selector, for: .touchUpInside)
    }


    ///
    ///
    class func colorForErrorView(_ opaque: Bool) -> UIColor {
        let alpha: CGFloat = opaque ? 1.0 : 0.95
        return UIColor(fromRGBAColorWithRed: 17.0, green: 17.0, blue: 17.0, alpha: alpha)
    }


    ///
    ///
    class func edgeInsetForLoginTextFields() -> UIEdgeInsets {
        return UIEdgeInsetsMake(7, 20, 7, 20)
    }

}
