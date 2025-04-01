import UIKit
import WordPressShared
import WordPressUI
import Gridicons
import AuthenticationServices

final class SubheadlineButton: UIButton {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            titleLabel?.font = WPStyleGuide.mediumWeightFont(forStyle: .subheadline)
            setTitleColor(WordPressAuthenticator.shared.style.textButtonColor, for: .normal)
            setTitleColor(WordPressAuthenticator.shared.style.textButtonHighlightColor, for: .highlighted)
        }
    }
}

extension WPStyleGuide {

    private struct Constants {
        static let textButtonMinHeight: CGFloat = 40.0
        static let googleIconOffset: CGFloat = -1.0
        static let googleIconButtonSize: CGFloat = 15.0
        static let domainsIconPaddingToRemove: CGFloat = 2.0
        static let domainsIconSize = CGSize(width: 18, height: 18)
        static let verticalLabelSpacing: CGFloat = 10.0
    }

    /// Calculate the border based on the display
    ///
    class var hairlineBorderWidth: CGFloat {
        return 1.0 / UIScreen.main.scale
    }

    /// Common view style for signin view controllers.
    ///
    /// - Parameters:
    ///     - view: The view to style.
    ///
    class func configureColorsForSigninView(_ view: UIView) {
        view.backgroundColor = wordPressBlue()
    }

    /// Configures a plain text button with default styles.
    ///
    class func configureTextButton(_ button: UIButton) {
        button.setTitleColor(WordPressAuthenticator.shared.style.textButtonColor, for: .normal)
        button.setTitleColor(WordPressAuthenticator.shared.style.textButtonHighlightColor, for: .highlighted)
    }

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
    class func mediumWeightFont(forStyle style: UIFont.TextStyle, maximumPointSize: CGFloat = WPStyleGuide.maxFontSize) -> UIFont {
        let fontToGetSize = WPStyleGuide.fontForTextStyle(style)
        let maxAllowedFontSize = CGFloat.minimum(fontToGetSize.pointSize, maximumPointSize)
        return UIFont.systemFont(ofSize: maxAllowedFontSize, weight: .medium)
    }

    // MARK: - Login Button Methods

    /// Creates a button for Google Sign-in with hyperlink style.
    ///
    /// - Returns: A properly styled UIButton
    ///
    class func googleLoginButton() -> UIButton {
        let baseString = NSLocalizedString("{G} Log in with Google.", comment: "Label for button to log in using Google. The {G} will be replaced with the Google logo.")

        let attrStrNormal = googleButtonString(baseString, linkColor: WordPressAuthenticator.shared.style.textButtonColor)
        let attrStrHighlight = googleButtonString(baseString, linkColor: WordPressAuthenticator.shared.style.textButtonHighlightColor)

        let font = WPStyleGuide.mediumWeightFont(forStyle: .subheadline)

        return textButton(normal: attrStrNormal, highlighted: attrStrHighlight, font: font)
    }

    /// Creates an attributed string that includes the Google logo.
    ///
    /// - Parameters:
    ///     - forHyperlink: Indicates if the string will be displayed in a hyperlink.
    ///                     Otherwise, it will be styled to be displayed on a NUXButton.
    /// - Returns: A properly styled NSAttributedString
    ///
    class func formattedGoogleString(forHyperlink: Bool = false) -> NSAttributedString {

        let googleAttachment = NSTextAttachment()
        let googleIcon = UIImage.googleIcon
        googleAttachment.image = googleIcon

        if forHyperlink {
            // Create an attributed string that contains the Google icon.
            let font = WPStyleGuide.mediumWeightFont(forStyle: .subheadline)
            googleAttachment.bounds = CGRect(x: 0,
                                             y: font.descender + Constants.googleIconOffset,
                                             width: googleIcon.size.width,
                                             height: googleIcon.size.height)

            return NSAttributedString(attachment: googleAttachment)
        } else {
            let nuxButtonTitleFont = WPStyleGuide.mediumWeightFont(forStyle: .title3)
            let googleTitle = NSLocalizedString("Continue with Google",
                                                comment: "Button title. Tapping begins log in using Google.")
            return attributedStringwithLogo(googleIcon,
                                            imageSize: .init(width: Constants.googleIconButtonSize, height: Constants.googleIconButtonSize),
                                            title: googleTitle,
                                            titleFont: nuxButtonTitleFont)
        }
    }

    /// Creates an attributed string that includes the Apple logo.
    ///
    /// - Returns: A properly styled NSAttributedString to be displayed on a NUXButton.
    ///
    class func formattedAppleString() -> NSAttributedString {
        let attributedString = NSMutableAttributedString()

        let appleSymbol = ""
        let appleSymbolAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 23)
        ]
        attributedString.append(NSAttributedString(string: appleSymbol, attributes: appleSymbolAttributes))

        // Add leading non-breaking space to separate the button text from the Apple symbol.
        let space = "\u{00a0}\u{00a0}"
        attributedString.append(NSAttributedString(string: space))

        let title = NSLocalizedString("Continue with Apple", comment: "Button title. Tapping begins log in using Apple.")
        attributedString.append(NSAttributedString(string: title))

        return NSAttributedString(attributedString: attributedString)
    }

    /// Creates an attributed string that includes the `linkFieldImage`
    ///
    /// - Returns: A properly styled NSAttributedString to be displayed on a NUXButton.
    ///
    class func formattedSignInWithSiteCredentialsString() -> NSAttributedString {
        let title = WordPressAuthenticator.shared.displayStrings.signInWithSiteCredentialsButtonTitle
        let globe = UIImage.gridicon(.globe)
        let image = globe.imageWithTintColor(WordPressAuthenticator.shared.style.placeholderColor) ?? globe
        return attributedStringwithLogo(image,
                                        imageSize: image.size,
                                        title: title,
                                        titleFont: WPStyleGuide.mediumWeightFont(forStyle: .title3))
    }

    /// Creates a button for Self-hosted Login
    ///
    /// - Returns: A properly styled UIButton
    ///
    class func selfHostedLoginButton(alignment: UIControl.NaturalContentHorizontalAlignment = .leading) -> UIButton {

        let style = WordPressAuthenticator.shared.style

        let button: UIButton

        if WordPressAuthenticator.shared.configuration.showLoginOptions {
            let baseString = NSLocalizedString("Or log in by _entering your site address_.", comment: "Label for button to log in using site address. Underscores _..._ denote underline.")

            let attrStrNormal = baseString.underlined(color: style.subheadlineColor, underlineColor: style.textButtonColor)
            let attrStrHighlight = baseString.underlined(color: style.subheadlineColor, underlineColor: style.textButtonHighlightColor)
            let font = WPStyleGuide.mediumWeightFont(forStyle: .subheadline)

            button = textButton(normal: attrStrNormal, highlighted: attrStrHighlight, font: font, alignment: alignment)
        } else {
            let baseString = NSLocalizedString("Enter the address of the WordPress site you'd like to connect.", comment: "Label for button to log in using your site address.")

            let attrStrNormal = selfHostedButtonString(baseString, linkColor: style.textButtonColor)
            let attrStrHighlight = selfHostedButtonString(baseString, linkColor: style.textButtonHighlightColor)
            let font = WPStyleGuide.mediumWeightFont(forStyle: .subheadline)

            button = textButton(normal: attrStrNormal, highlighted: attrStrHighlight, font: font)
        }

        button.accessibilityIdentifier = "Self Hosted Login Button"

        return button
    }

    /// Creates a button for wpcom signup on the email screen
    ///
    /// - Returns: A UIButton styled for wpcom signup
    /// - Note: This button is only used during Jetpack setup, not the usual flows
    ///
    class func wpcomSignupButton() -> UIButton {
        let style = WordPressAuthenticator.shared.style
        let baseString = NSLocalizedString("Don't have an account? _Sign up_", comment: "Label for button to log in using your site address. The underscores _..._ denote underline")
        let attrStrNormal = baseString.underlined(color: style.subheadlineColor, underlineColor: style.textButtonColor)
        let attrStrHighlight = baseString.underlined(color: style.subheadlineColor, underlineColor: style.textButtonHighlightColor)
        let font = WPStyleGuide.mediumWeightFont(forStyle: .subheadline)

        return textButton(normal: attrStrNormal, highlighted: attrStrHighlight, font: font)
    }

    /// Creates a button to open our T&C
    ///
    /// - Returns: A properly styled UIButton
    ///
    class func termsButton() -> UIButton {
        let style = WordPressAuthenticator.shared.style

        let baseString = NSLocalizedString("By signing up, you agree to our _Terms of Service_.", comment: "Legal disclaimer for signup buttons, the underscores _..._ denote underline")

        let attrStrNormal = baseString.underlined(color: style.subheadlineColor, underlineColor: style.textButtonColor)
        let attrStrHighlight = baseString.underlined(color: style.subheadlineColor, underlineColor: style.textButtonHighlightColor)
        let font = WPStyleGuide.mediumWeightFont(forStyle: .footnote)

        return textButton(normal: attrStrNormal, highlighted: attrStrHighlight, font: font, alignment: .center)
    }

    /// Creates a button to open our T&C.
    /// Specifically, the Sign Up verbiage on the Get Started view.
    /// - Returns: A properly styled UIButton
    ///
    class func signupTermsButton() -> UIButton {
        let unifiedStyle = WordPressAuthenticator.shared.unifiedStyle
        let originalStyle = WordPressAuthenticator.shared.style
        let baseString = WordPressAuthenticator.shared.displayStrings.signupTermsOfService
        let textColor = unifiedStyle?.textSubtleColor ?? originalStyle.subheadlineColor
        let linkColor = unifiedStyle?.textButtonColor ?? originalStyle.textButtonColor

        let attrStrNormal = baseString.underlined(color: textColor, underlineColor: linkColor)
        let attrStrHighlight = baseString.underlined(color: textColor, underlineColor: linkColor)
        let font = WPStyleGuide.mediumWeightFont(forStyle: .footnote)

        let button = textButton(normal: attrStrNormal, highlighted: attrStrHighlight, font: font, alignment: .center, forUnified: true)
        button.titleLabel?.textAlignment = .center
        return button
    }

    private class func textButton(normal normalString: NSAttributedString, highlighted highlightString: NSAttributedString, font: UIFont, alignment: UIControl.NaturalContentHorizontalAlignment = .leading, forUnified: Bool = false) -> UIButton {
        let button = SubheadlineButton()
        button.clipsToBounds = true

        button.naturalContentHorizontalAlignment = alignment
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = font
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.setTitleColor(WordPressAuthenticator.shared.style.subheadlineColor, for: .normal)

        // These constraints work around some issues with multiline buttons and
        // vertical layout.  Without them the button's height may not account
        // for the titleLabel's height.

        let verticalLabelSpacing = forUnified ? 0 : Constants.verticalLabelSpacing
        button.titleLabel?.topAnchor.constraint(equalTo: button.topAnchor, constant: verticalLabelSpacing).isActive = true
        button.titleLabel?.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -verticalLabelSpacing).isActive = true
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.textButtonMinHeight).isActive = true

        button.setAttributedTitle(normalString, for: .normal)
        button.setAttributedTitle(highlightString, for: .highlighted)
        return button
    }

    private class func googleButtonString(_ baseString: String, linkColor: UIColor) -> NSAttributedString {
        let labelParts = baseString.components(separatedBy: "{G}")

        let firstPart = labelParts[0]
        // 👇 don't want to crash when a translation lacks "{G}"
        let lastPart = labelParts.indices.contains(1) ? labelParts[1] : ""

        let labelString = NSMutableAttributedString(string: firstPart, attributes: [.foregroundColor: WPStyleGuide.greyDarken30()])

        if lastPart != "" {
            labelString.append(formattedGoogleString(forHyperlink: true))
        }

        labelString.append(NSAttributedString(string: lastPart, attributes: [.foregroundColor: linkColor]))

        return labelString
    }

    private class func selfHostedButtonString(_ buttonText: String, linkColor: UIColor) -> NSAttributedString {
        let font = WPStyleGuide.mediumWeightFont(forStyle: .subheadline)

        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.alignment = .left

        let labelString = NSMutableAttributedString(string: "")

        if let originalDomainsIcon = UIImage.gridicon(.domains).imageWithTintColor(WordPressAuthenticator.shared.style.placeholderColor) {
            var domainsIcon = originalDomainsIcon.cropping(to: CGRect(x: Constants.domainsIconPaddingToRemove,
                                                                      y: Constants.domainsIconPaddingToRemove,
                                                                      width: originalDomainsIcon.size.width - Constants.domainsIconPaddingToRemove * 2,
                                                                      height: originalDomainsIcon.size.height - Constants.domainsIconPaddingToRemove * 2))
            domainsIcon = domainsIcon.resized(to: Constants.domainsIconSize)
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

// MARK: Attributed String Helpers
//
private extension WPStyleGuide {

    /// Creates an attributed string with a logo and title.
    ///  The logo is prepended to the title.
    ///
    /// - Parameters:
    ///     - logoImage: UIImage representing the logo
    ///     - imageSize: Size of the UIImage
    ///     - title: title String to be appended to the logoImage
    ///     - titleFont: UIFont for the title String
    ///
    /// - Returns: A properly styled NSAttributedString to be displayed on a NUXButton.
    ///
    class func attributedStringwithLogo(_ logoImage: UIImage,
                                        imageSize: CGSize,
                                        title: String,
                                        titleFont: UIFont) -> NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = logoImage

        attachment.bounds = CGRect(x: 0, y: (titleFont.capHeight - imageSize.height) / 2,
                                   width: imageSize.width, height: imageSize.height)

        let buttonString = NSMutableAttributedString(attachment: attachment)
        //  Add leading non-breaking spaces to separate the button text from the logo.
        let title = "\u{00a0}\u{00a0}" + title
        buttonString.append(NSAttributedString(string: title))

        return buttonString
    }
}
