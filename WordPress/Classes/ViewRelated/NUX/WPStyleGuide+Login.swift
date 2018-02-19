import WordPressShared

extension WPStyleGuide {

    private struct Constants {
        static let buttonMinHeight: CGFloat = 40.0
        static let googleIconOffset: CGFloat = -1.0
        static let verticalLabelSpacing: CGFloat = 10.0
    }

    /// Common view style for signin view controllers.
    ///
    /// - Parameters:
    ///     - view: The view to style.
    ///
    @objc class func configureColorsForSigninView(_ view: UIView) {
        view.backgroundColor = wordPressBlue()
    }

    /// Adds a 1password button to a WPWalkthroughTextField, if available
    ///
    @objc class func configureOnePasswordButtonForTextfield(_ textField: WPWalkthroughTextField, target: NSObject, selector: Selector) {
        guard OnePasswordFacade.isOnePasswordEnabled else {
            return
        }

        let onePasswordButton = UIButton(type: .custom)
        onePasswordButton.setImage(UIImage(named: "onepassword-wp-button"), for: UIControlState())
        onePasswordButton.sizeToFit()

        textField.rightView = onePasswordButton
        textField.rightViewMode = .always

        onePasswordButton.addTarget(target, action: selector, for: .touchUpInside)
    }

    /// Adds a 1password button to a stack view, if available
    ///
    @objc class func configureOnePasswordButtonForStackView(_ stack: UIStackView, target: NSObject, selector: Selector) {
        guard OnePasswordFacade.isOnePasswordEnabled else {
            return
        }

        let onePasswordButton = UIButton(type: .custom)
        onePasswordButton.setImage(UIImage(named: "onepassword-wp-button"), for: UIControlState())
        onePasswordButton.sizeToFit()
        onePasswordButton.setContentHuggingPriority(.required, for: .horizontal)
        onePasswordButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        stack.addArrangedSubview(onePasswordButton)

        onePasswordButton.addTarget(target, action: selector, for: .touchUpInside)
    }

    ///
    ///
    @objc class func colorForErrorView(_ opaque: Bool) -> UIColor {
        let alpha: CGFloat = opaque ? 1.0 : 0.95
        return UIColor(fromRGBAColorWithRed: 17.0, green: 17.0, blue: 17.0, alpha: alpha)
    }

    ///
    ///
    @objc class func edgeInsetForLoginTextFields() -> UIEdgeInsets {
        return UIEdgeInsets(top: 7, left: 20, bottom: 7, right: 20)
    }

    @objc class func textInsetsForLoginTextFieldWithLeftView() -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
    }

    /// Return the system font in medium weight for the given style
    ///
    /// - note: iOS won't return UIFontWeightMedium for dynamic system font :(
    /// So instead get the dynamic font size, then ask for the non-dynamic font at that size
    ///
    @objc class func mediumWeightFont(forStyle style: UIFontTextStyle) -> UIFont {
        let fontToGetSize = WPStyleGuide.fontForTextStyle(style)
        return UIFont.systemFont(ofSize: fontToGetSize.pointSize, weight: .medium)
    }

    // MARK: - Google Signin Button Methods

    /// Creates a button for Google Sign-in
    ///
    /// - Returns: A properly styled UIButton
    ///
    @objc class func googleLoginButton() -> UIButton {
        let baseString =  NSLocalizedString("Or you can {G} Log in with Google.", comment: "Label for button to log in using Google. The {G} will be replaced with the Google logo.")

        let attrStrNormal = googleButtonString(baseString, linkColor: WPStyleGuide.wordPressBlue())
        let attrStrHighlight = googleButtonString(baseString, linkColor: WPStyleGuide.lightBlue())

        let font = WPStyleGuide.mediumWeightFont(forStyle: .subheadline)

        return textButton(normal: attrStrNormal, highlighted: attrStrHighlight, font: font)
    }

    /// Creates a button to open our T&C
    ///
    /// - Returns: A properly styled UIButton
    ///
    class func termsButton() -> UIButton {
        let baseString =  NSLocalizedString("By choosing \"Sign up\" you agree to our _Terms of Service_", comment: "Legal disclaimer for signup buttons. Sign Up must match button phrasing, two underscores _..._ denote underline")

        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.alignment = .center

        let labelParts = baseString.components(separatedBy: "_")
        let firstPart = labelParts[0]
        let underlinePart = labelParts.indices.contains(1) ? labelParts[1] : ""
        let lastPart = labelParts.indices.contains(2) ? labelParts[2] : ""

        let labelString = NSMutableAttributedString(string: firstPart, attributes: [.paragraphStyle: titleParagraphStyle])
        labelString.append(NSAttributedString(string: underlinePart, attributes: [.underlineStyle: NSUnderlineStyle.styleSingle.rawValue]))
        labelString.append(NSAttributedString(string: lastPart))

        let font = WPStyleGuide.mediumWeightFont(forStyle: .caption2)
        return textButton(normal: labelString, highlighted: labelString, font: font)
    }

    private class func textButton(normal normalString: NSAttributedString, highlighted highlightString: NSAttributedString, font: UIFont) -> UIButton {
        let button = UIButton()
        button.clipsToBounds = true

        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = font
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.lineBreakMode = .byWordWrapping

        // These constraints work around some issues with multiline buttons and
        // vertical layout.  Without them the button's height may not account
        // for the titleLabel's height.
        button.titleLabel?.topAnchor.constraint(equalTo: button.topAnchor, constant: Constants.verticalLabelSpacing).isActive = true
        button.titleLabel?.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -Constants.verticalLabelSpacing).isActive = true
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.buttonMinHeight).isActive = true


        button.setAttributedTitle(normalString, for: .normal)
        button.setAttributedTitle(highlightString, for: .highlighted)
        return button
    }

    private class func googleButtonString(_ baseString: String, linkColor: UIColor) -> NSAttributedString {
        let labelParts = baseString.components(separatedBy: "{G}")
        let font = WPStyleGuide.mediumWeightFont(forStyle: .subheadline)

        let firstPart = labelParts[0]
        // 👇 don't want to crash when a translation lacks "{G}"
        let lastPart = labelParts.indices.contains(1) ? labelParts[1] : ""

        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.alignment = .left
        let labelString = NSMutableAttributedString(string: firstPart, attributes: [.foregroundColor: WPStyleGuide.greyDarken30(), .paragraphStyle: titleParagraphStyle])

        if let googleIcon = UIImage(named: "google"), lastPart != "" {
            let googleAttachment = NSTextAttachment()
            googleAttachment.image = googleIcon
            googleAttachment.bounds = CGRect(x: 0.0, y: font.descender + Constants.googleIconOffset, width: googleIcon.size.width, height: googleIcon.size.height)
            let iconString = NSAttributedString(attachment: googleAttachment)
            labelString.append(iconString)
        }

        labelString.append(NSAttributedString(string: lastPart, attributes: [.foregroundColor: linkColor]))

        return labelString
    }
}
