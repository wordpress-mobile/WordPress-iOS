import WordPressShared
import WordPressUI
import Gridicons

extension WPStyleGuide {

    private struct Constants {
        static let buttonMinHeight: CGFloat = 40.0
        static let googleIconOffset: CGFloat = -1.0
        static let domainsIconPaddingToRemove: CGFloat = 2.0
        static let domainsIconSize = CGSize(width: 18, height: 18)
        static let verticalLabelSpacing: CGFloat = 10.0
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
        onePasswordButton.setContentHuggingPriority(.required, for: .horizontal)
        onePasswordButton.setContentCompressionResistancePriority(.required, for: .horizontal)

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
        return UIEdgeInsets(top: 7, left: 20, bottom: 7, right: 20)
    }

    class func textInsetsForLoginTextFieldWithLeftView() -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
    }

    /// Return the system font in medium weight for the given style
    ///
    /// - note: iOS won't return UIFontWeightMedium for dynamic system font :(
    /// So instead get the dynamic font size, then ask for the non-dynamic font at that size
    ///
    class func mediumWeightFont(forStyle style: UIFontTextStyle) -> UIFont {
        let fontToGetSize = WPStyleGuide.fontForTextStyle(style)
        return UIFont.systemFont(ofSize: fontToGetSize.pointSize, weight: .medium)
    }

    // MARK: - Google Signin Button Methods

    /// Creates a button for Google Sign-in
    ///
    /// - Returns: A properly styled UIButton
    ///
    class func googleLoginButton() -> UIButton {
        let baseString =  NSLocalizedString("{G} Log in with Google.", comment: "Label for button to log in using Google. The {G} will be replaced with the Google logo.")

        let attrStrNormal = googleButtonString(baseString, linkColor: WPStyleGuide.wordPressBlue())
        let attrStrHighlight = googleButtonString(baseString, linkColor: WPStyleGuide.lightBlue())

        let font = WPStyleGuide.mediumWeightFont(forStyle: .subheadline)

        return textButton(normal: attrStrNormal, highlighted: attrStrHighlight, font: font)
    }

    /// Creates a button for Self-hosted Login
    ///
    /// - Returns: A properly styled UIButton
    ///
    class func selfHostedLoginButton() -> UIButton {
        let baseString =  NSLocalizedString("Log in by entering your site address.", comment: "Label for button to log in using your site address.")

        let attrStrNormal = selfHostedButtonString(baseString, linkColor: WPStyleGuide.wordPressBlue())
        let attrStrHighlight = selfHostedButtonString(baseString, linkColor: WPStyleGuide.lightBlue())

        let font = WPStyleGuide.mediumWeightFont(forStyle: .subheadline)

        return textButton(normal: attrStrNormal, highlighted: attrStrHighlight, font: font)
    }

    /// Creates a button to open our T&C
    ///
    /// - Returns: A properly styled UIButton
    ///
    class func termsButton() -> UIButton {
        let baseString =  NSLocalizedString("By choosing \"Sign up\" you agree to our _Terms of Service_", comment: "Legal disclaimer for signup buttons. Sign Up must match button phrasing, two underscores _..._ denote underline")

        let labelParts = baseString.components(separatedBy: "_")
        let firstPart = labelParts[0]
        let underlinePart = labelParts.indices.contains(1) ? labelParts[1] : ""
        let lastPart = labelParts.indices.contains(2) ? labelParts[2] : ""

        let labelString = NSMutableAttributedString(string: firstPart)
        labelString.append(NSAttributedString(string: underlinePart, attributes: [.underlineStyle: NSUnderlineStyle.styleSingle.rawValue]))
        labelString.append(NSAttributedString(string: lastPart))

        let font = WPStyleGuide.mediumWeightFont(forStyle: .caption2)
        return textButton(normal: labelString, highlighted: labelString, font: font, alignment: .center)
    }

    private class func textButton(normal normalString: NSAttributedString, highlighted highlightString: NSAttributedString, font: UIFont, alignment: UIControl.NaturalContentHorizontalAlignment = .leading) -> UIButton {
        let button = UIButton()
        button.clipsToBounds = true

        button.naturalContentHorizontalAlignment = alignment
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

        let labelString = NSMutableAttributedString(string: firstPart, attributes: [.foregroundColor: WPStyleGuide.greyDarken30()])

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

    private class func selfHostedButtonString(_ buttonText: String, linkColor: UIColor) -> NSAttributedString {
        let font = WPStyleGuide.mediumWeightFont(forStyle: .subheadline)

        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.alignment = .left

        let labelString = NSMutableAttributedString(string: "")

        if let originalDomainsIcon = Gridicon.iconOfType(.domains).imageWithTintColor(WPStyleGuide.greyLighten10()) {
            var domainsIcon = originalDomainsIcon.cropping(to: CGRect(x: Constants.domainsIconPaddingToRemove,
                                                                      y: Constants.domainsIconPaddingToRemove,
                                                                      width: originalDomainsIcon.size.width - Constants.domainsIconPaddingToRemove * 2,
                                                                      height: originalDomainsIcon.size.height - Constants.domainsIconPaddingToRemove * 2))
            domainsIcon = domainsIcon.resizedImage(Constants.domainsIconSize, interpolationQuality: .high)
            let domainsAttachment = NSTextAttachment()
            domainsAttachment.image = domainsIcon
            domainsAttachment.bounds = CGRect(x: 0, y: font.descender, width: domainsIcon.size.width, height: domainsIcon.size.height)
            let iconString = NSAttributedString(attachment: domainsAttachment)
            labelString.append(iconString)
        }
        labelString.append(NSAttributedString(string: " " + buttonText, attributes: [.foregroundColor: linkColor]))

        return labelString
    }
}
