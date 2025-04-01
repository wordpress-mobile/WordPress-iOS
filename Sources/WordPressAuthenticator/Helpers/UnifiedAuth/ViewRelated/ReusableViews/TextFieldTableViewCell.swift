import UIKit
import WordPressShared

/// TextFieldTableViewCell: a textfield with a custom border line in a UITableViewCell.
///
final class TextFieldTableViewCell: UITableViewCell {

    /// Private properties.
    ///
    @IBOutlet private weak var borderView: UIView!
    @IBOutlet private weak var borderWidth: NSLayoutConstraint!
    private var secureTextEntryToggle: UIButton?
    private var secureTextEntryImageVisible: UIImage?
    private var secureTextEntryImageHidden: UIImage?
    private var textfieldStyle: TextFieldStyle = .url

    /// Register an action for the SiteAddress URL textfield.
    /// - Note: we have to manually add an action to the textfield
    ///	        because the delegate method `textFieldDidChangeSelection(_ textField: UITextField)`
    ///         is only available to iOS 13+. When we no longer support iOS 12,
    ///			`registerTextFieldAction`, `textFieldDidChangeSelection`, and `onChangeSelectionHandler` can
    ///			be deleted in favor of adding the delegate method to SiteAddressViewController.
    @IBAction func registerTextFieldAction() {
        onChangeSelectionHandler?(textField)
    }

    /// Public properties.
    ///
    @IBOutlet public weak var textField: UITextField! // public so it can be the first responder
    @IBInspectable public var showSecureTextEntryToggle: Bool = false {
        didSet {
            configureSecureTextEntryToggle()
        }
    }

    public var onChangeSelectionHandler: ((_ sender: UITextField) -> Void)?
    public static let reuseIdentifier = "TextFieldTableViewCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        styleBorder()
        setCommonTextFieldStyles()
    }

    /// Configures the textfield for URL, username, or entering a password.
    /// - Parameter style: changes the textfield behavior and appearance.
    /// - Parameter placeholder: the placeholder text, if any.
    /// - Parameter text: the field text, if any.
    ///
    public func configure(withStyle style: TextFieldStyle = .url, placeholder: String? = nil, text: String? = nil) {
        textfieldStyle = style
        applyTextFieldStyle(style)
        textField.placeholder = placeholder
        textField.text = text
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        textField.keyboardType = .default
        textField.returnKeyType = .default
        setSecureTextEntry(false)
        showSecureTextEntryToggle = false
        textField.rightView = nil
        textField.accessibilityLabel = nil
        textField.accessibilityIdentifier = nil
    }
}

// MARK: - Private methods
private extension TextFieldTableViewCell {

    /// Style the bottom cell border, called borderView.
    ///
    func styleBorder() {
        let borderColor = WordPressAuthenticator.shared.unifiedStyle?.borderColor ?? WordPressAuthenticator.shared.style.primaryNormalBorderColor
        borderView.backgroundColor = borderColor
        borderWidth.constant = WPStyleGuide.hairlineBorderWidth
    }

    /// Apply common keyboard traits and font styles.
    ///
    func setCommonTextFieldStyles() {
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        textField.autocorrectionType = .no
    }

    /// Sets the textfield keyboard type and applies common traits.
    /// - note: Don't assign first responder here. It's too early in the view lifecycle.
    ///
    func applyTextFieldStyle(_ style: TextFieldStyle) {
        switch style {
        case .url:
            textField.keyboardType = .URL
            textField.returnKeyType = .continue
            registerTextFieldAction()
            textField.accessibilityLabel = Constants.siteAddress
            textField.accessibilityIdentifier = Constants.siteAddressID
        case .username:
            textField.keyboardType = .default
            textField.returnKeyType = .next
            textField.accessibilityLabel = Constants.username
            textField.accessibilityIdentifier = Constants.usernameID
        case .password:
            textField.keyboardType = .default
            textField.returnKeyType = .continue
            setSecureTextEntry(true)
            showSecureTextEntryToggle = true
            configureSecureTextEntryToggle()
            textField.accessibilityLabel = Constants.password
            textField.accessibilityIdentifier = Constants.passwordID
        case .numericCode:
            textField.keyboardType = .numberPad
            textField.returnKeyType = .continue
            textField.accessibilityLabel = Constants.otp
            textField.accessibilityIdentifier = Constants.otpID
        case .email:
            textField.keyboardType = .emailAddress
            textField.returnKeyType = .continue
            textField.textContentType = .username // So the password autofill appears on the keyboard
            textField.accessibilityLabel = Constants.email
            textField.accessibilityIdentifier = Constants.emailID
        }
        if WordPressAuthenticator.shared.configuration.disableAutofill {
            textField.textContentType = nil
        }
    }

    /// Call the handler when the textfield changes.
    ///
    @objc func textFieldDidChangeSelection() {
        onChangeSelectionHandler?(textField)
    }
}

// MARK: - Secure Text Entry
/// Methods ported from WPWalkthroughTextField.h/.m
///
private extension TextFieldTableViewCell {

    /// Build the show / hide icon in the textfield.
    ///
    func configureSecureTextEntryToggle() {
        guard showSecureTextEntryToggle else {
            return
        }

        secureTextEntryImageVisible = UIImage.gridicon(.visible)
        secureTextEntryImageHidden = UIImage.gridicon(.notVisible)

        secureTextEntryToggle = UIButton(type: .custom)
        secureTextEntryToggle?.clipsToBounds = true
        // The icon should match the border color.
        let tintColor = WordPressAuthenticator.shared.unifiedStyle?.borderColor ?? WordPressAuthenticator.shared.style.primaryNormalBorderColor
        secureTextEntryToggle?.tintColor = tintColor

        secureTextEntryToggle?.addTarget(self,
                                         action: #selector(secureTextEntryToggleAction),
                                         for: .touchUpInside)

        updateSecureTextEntryToggleImage()
        updateSecureTextEntryForAccessibility()
        textField.rightView = secureTextEntryToggle
        textField.rightViewMode = .always
    }

    func setSecureTextEntry(_ secureTextEntry: Bool) {
        textField.font = UIFont.preferredFont(forTextStyle: .body)

        textField.isSecureTextEntry = secureTextEntry
        updateSecureTextEntryToggleImage()
        updateSecureTextEntryForAccessibility()
    }

    @objc func secureTextEntryToggleAction(_ sender: Any) {
        textField.isSecureTextEntry = !textField.isSecureTextEntry

        // Save and re-apply the current selection range to save the cursor position
        let currentTextRange = textField.selectedTextRange
        textField.becomeFirstResponder()
        textField.selectedTextRange = currentTextRange
        updateSecureTextEntryToggleImage()
        updateSecureTextEntryForAccessibility()
    }

    func updateSecureTextEntryToggleImage() {
        let image = textField.isSecureTextEntry ? secureTextEntryImageHidden : secureTextEntryImageVisible
        secureTextEntryToggle?.setImage(image, for: .normal)
        secureTextEntryToggle?.sizeToFit()
    }

    func updateSecureTextEntryForAccessibility() {
        secureTextEntryToggle?.accessibilityLabel = Constants.showPassword
        secureTextEntryToggle?.accessibilityIdentifier = Constants.showPassword
        secureTextEntryToggle?.accessibilityValue = textField.isSecureTextEntry ? Constants.passwordHidden : Constants.passwordShown
    }
}

// MARK: - Constants
extension TextFieldTableViewCell {

    /// TextField configuration options.
    ///
    enum TextFieldStyle {
        case url
        case username
        case password
        case numericCode
        case email
    }

    struct Constants {
        /// Accessibility Hints
        ///
        static let passwordHidden = NSLocalizedString("Hidden",
                                                      comment: "Accessibility value if login page's password field is hiding the password (i.e. with asterisks).")
        static let passwordShown = NSLocalizedString("Shown",
                                                     comment: "Accessibility value if login page's password field is displaying the password.")
        static let showPassword = NSLocalizedString("Show password",
                                                    comment: "Accessibility label for the 'Show password' button in the login page's password field.")
        static let siteAddress = NSLocalizedString("Site address",
                                                   comment: "Accessibility label of the site address field shown when adding a self-hosted site.")
        static let username = NSLocalizedString("Username",
                                                comment: "Accessibility label for the username text field in the self-hosted login page.")
        static let password = NSLocalizedString("Password",
                                                comment: "Accessibility label for the password text field in the self-hosted login page.")
        static let otp = NSLocalizedString("Authentication code",
                                           comment: "Accessibility label for the 2FA text field.")
        static let email = NSLocalizedString("Email address",
                                             comment: "Accessibility label for the email address text field.")
        static let siteAddressID = "Site address"
        static let usernameID = "Username"
        static let passwordID = "Password"
        static let otpID = "Authentication code"
        static let emailID = "Email address"
    }
}
