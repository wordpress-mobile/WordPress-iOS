import WordPressShared

extension WPStyleGuide {

    private struct Constants {
        static let labelMinHeight: CGFloat = 30.0
        static let googleIconOffset: CGFloat = -1.0
        static let verticalPadding: CGFloat = 5.0
    }

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

    // MARK: - Google Signin Button Methods

    /// A factory method for getting a button for Google Sign-in
    ///
    /// - Returns: A properly styled UIButton
    ///
    class func googleLoginButton() -> UIButton {
        let baseString =  NSLocalizedString("Or you can {G} Log in with Google.", comment: "Label for button to log in using Google. The {G} will be replaced with the Google logo.")

        let font = WPStyleGuide.mediumWeightFont(forStyle: .subheadline)
        let button = UIButton()
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentHorizontalAlignment = .left
        button.titleLabel?.font = font
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.lineBreakMode = .byWordWrapping

        // Manually setting constraints to ensure that a multiline lable is fully
        // visible. Some layout scenarios seem to cause the button height to size
        // smaller than the text in the label.
        // The constant in the anchors are to ensure there is always a
        // consistent amount of space between the top and bottom of the label and
        // the containing button.  Edge insets can also do this but do not
        // solve the height issue.
        button.titleLabel?.topAnchor.constraint(equalTo: button.topAnchor, constant: 10).isActive = true
        button.titleLabel?.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -10).isActive = true

        let attrStrNormal = googleButtonString(baseString, for: font, linkColor: WPStyleGuide.wordPressBlue())
        let attrStrHiglight = googleButtonString(baseString, for: font, linkColor: WPStyleGuide.lightBlue())
        button.setAttributedTitle(attrStrNormal, for: .normal)
        button.setAttributedTitle(attrStrHiglight, for: .highlighted)
        return button
    }

    private class func googleButtonString(_ baseString: String, for font: UIFont, linkColor: UIColor) -> NSAttributedString {
        let labelParts = baseString.components(separatedBy: "{G}")

        let firstPart = labelParts[0]
        // 👇 don't want to crash when a translation lacks "{G}"
        let lastPart = labelParts.indices.contains(1) ? labelParts[1] : ""

        let labelString = NSMutableAttributedString(string: firstPart, attributes: [NSForegroundColorAttributeName: WPStyleGuide.greyDarken30()])

        if let googleIcon = UIImage(named: "google"), lastPart != "" {
            let googleAttachment = NSTextAttachment()
            googleAttachment.image = googleIcon
            googleAttachment.bounds = CGRect(x: 0.0, y: font.descender + Constants.googleIconOffset, width: googleIcon.size.width, height: googleIcon.size.height)
            let iconString = NSAttributedString(attachment: googleAttachment)
            labelString.append(iconString)
        }

        labelString.append(NSAttributedString(string: lastPart, attributes: [NSForegroundColorAttributeName: linkColor]))

        return labelString
    }
}
