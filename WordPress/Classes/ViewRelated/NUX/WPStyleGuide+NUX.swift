import WordPressShared

extension WPStyleGuide
{

    /// Common view style for signin view controllers.
    ///
    /// - Parameters:
    ///     - view: The view to style.
    ///
    class func configureColorsForSigninView(view: UIView) {
        view.backgroundColor = wordPressBlue()
    }


    ///
    ///
    class func configureOnePasswordButtonForTextfield(textField: WPWalkthroughTextField, target: NSObject, selector: Selector) {
        if !OnePasswordFacade().isOnePasswordEnabled() {
            return
        }

        let onePasswordButton = UIButton(type: .Custom)
        onePasswordButton.setImage(UIImage(named: "onepassword-wp-button"), forState: .Normal)
        onePasswordButton.sizeToFit()

        textField.rightView = onePasswordButton
        textField.rightViewPadding = UIOffset(horizontal: 9.0, vertical: 0.0)
        textField.rightViewMode = .Always

        onePasswordButton.addTarget(target, action: selector, forControlEvents: .TouchUpInside)
    }


    ///
    ///
    class func colorForErrorView(opaque: Bool) -> UIColor {
        let alpha: CGFloat = opaque ? 1.0 : 0.95
        return UIColor(fromRGBAColorWithRed: 17.0, green: 17.0, blue: 17.0, alpha:alpha)
    }

}
