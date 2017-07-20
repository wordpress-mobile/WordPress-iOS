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

    /// Adds a 1password button to a WPWalkthroughTextField, if available
    ///
    class func configureOnePasswordButtonForTextfield(_ textField: WPWalkthroughTextField, target: NSObject, selector: Selector) {
        if !OnePasswordFacade().isOnePasswordEnabled() {
            return
        }

        let onePasswordButton = UIButton(type: .custom)
        onePasswordButton.setImage(UIImage(named: "onepassword-wp-button"), for: UIControlState())
        onePasswordButton.sizeToFit()

        textField.rightView = onePasswordButton
        textField.rightViewPadding = UIOffset(horizontal: 20.0, vertical: 0.0)
        textField.rightViewMode = .always

        onePasswordButton.addTarget(target, action: selector, for: .touchUpInside)
    }

    /// Adds a 1password button to a stack view, if available
    ///
    class func configureOnePasswordButtonForStackView(_ stack: UIStackView, target: NSObject, selector: Selector) {
        if !OnePasswordFacade().isOnePasswordEnabled() {
            return
        }

        let onePasswordButton = UIButton(type: .custom)
        onePasswordButton.setImage(UIImage(named: "onepassword-wp-button"), for: UIControlState())
        onePasswordButton.sizeToFit()
        onePasswordButton.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
        onePasswordButton.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)

        stack.addArrangedSubview(onePasswordButton)

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

    /// Return the system font in medium weight for the given style
    ///
    /// - note: iOS won't return UIFontWeightMedium for dynamic system font :(
    /// So instead get the dynamic font size, then ask for the non-dynamic font at that size
    ///
    class func mediumWeightFont(forStyle style: UIFontTextStyle) -> UIFont {
        let fontToGetSize = WPStyleGuide.fontForTextStyle(style)
        return UIFont.systemFont(ofSize: fontToGetSize.pointSize, weight: UIFontWeightMedium)
    }
}
