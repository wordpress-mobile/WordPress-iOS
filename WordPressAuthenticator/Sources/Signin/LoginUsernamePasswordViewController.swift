import UIKit
import WordPressShared

/// Part two of the self-hosted sign in flow. For use by WCiOS only.
/// A valid site address should be acquired before presenting this view controller.
///
class LoginUsernamePasswordViewController: LoginViewController, NUXKeyboardResponder {
    @IBOutlet var siteHeaderView: SiteInfoHeaderView!
    @IBOutlet var usernameField: WPWalkthroughTextField!
    @IBOutlet var passwordField: WPWalkthroughTextField!
    @IBOutlet var forgotPasswordButton: UIButton!
    @IBOutlet var bottomContentConstraint: NSLayoutConstraint?
    @IBOutlet var verticalCenterConstraint: NSLayoutConstraint?
    override var sourceTag: WordPressSupportSourceTag {
        get {
            return .loginWPComUsernamePassword
        }
    }

    override var loginFields: LoginFields {
        didSet {
            // Clear the username & password (if any) from LoginFields
            loginFields.username = ""
            loginFields.password = ""
        }
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        configureHeader()
        localizeControls()
        displayLoginMessage("")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Update special case login fields.
        loginFields.meta.userIsDotCom = true

        configureTextFields()
        configureSubmitButton(animating: false)
        configureViewForEditingIfNeeded()

        setupNavBarIcon()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        registerForKeyboardEvents(keyboardWillShowAction: #selector(handleKeyboardWillShow(_:)),
                                  keyboardWillHideAction: #selector(handleKeyboardWillHide(_:)))

        WordPressAuthenticator.track(.loginUsernamePasswordFormViewed)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterForKeyboardEvents()
    }

    // MARK: - Setup and Configuration

    /// Assigns localized strings to various UIControl defined in the storyboard.
    ///
    @objc func localizeControls() {
        instructionLabel?.text = WordPressAuthenticator.shared.displayStrings.usernamePasswordInstructions

        usernameField.placeholder = NSLocalizedString("Username", comment: "Username placeholder")
        passwordField.placeholder = NSLocalizedString("Password", comment: "Password placeholder")

        let submitButtonTitle = NSLocalizedString("Next", comment: "Title of a button. The text should be capitalized.").localizedCapitalized
        submitButton?.setTitle(submitButtonTitle, for: .normal)
        submitButton?.setTitle(submitButtonTitle, for: .highlighted)

        let forgotPasswordTitle = NSLocalizedString("Lost your password?", comment: "Title of a button. ")
        forgotPasswordButton.setTitle(forgotPasswordTitle, for: .normal)
        forgotPasswordButton.setTitle(forgotPasswordTitle, for: .highlighted)
        forgotPasswordButton.titleLabel?.numberOfLines = 0
    }

    /// Configures the content of the text fields based on what is saved in `loginFields`.
    ///
    @objc func configureTextFields() {
        usernameField.text = loginFields.username
        passwordField.text = loginFields.password
        passwordField.contentInsets = WPStyleGuide.edgeInsetForLoginTextFields()
        usernameField.contentInsets = WPStyleGuide.edgeInsetForLoginTextFields()
    }

    /// Configures the appearance and state of the forgot password button.
    ///
    @objc func configureForgotPasswordButton() {
        forgotPasswordButton.isEnabled = enableSubmit(animating: false)
        WPStyleGuide.configureTextButton(forgotPasswordButton)
    }

    /// Configures the appearance and state of the submit button.
    ///
    override func configureSubmitButton(animating: Bool) {
        submitButton?.showActivityIndicator(animating)

        submitButton?.isEnabled = (
            !animating &&
                !loginFields.username.isEmpty &&
                !loginFields.password.isEmpty
        )
    }

    /// Sets the view's state to loading or not loading.
    ///
    /// - Parameter loading: True if the form should be configured to a "loading" state.
    ///
    override func configureViewLoading(_ loading: Bool) {
        usernameField.isEnabled = !loading
        passwordField.isEnabled = !loading

        configureSubmitButton(animating: loading)
        configureForgotPasswordButton()
        navigationItem.hidesBackButton = loading
    }

    /// Configure the view for an editing state. Should only be called from viewWillAppear
    /// as this method skips animating any change in height.
    ///
    @objc func configureViewForEditingIfNeeded() {
        // Check the helper to determine whether an editiing state should be assumed.
        adjustViewForKeyboard(SigninEditingState.signinEditingStateActive)
        if SigninEditingState.signinEditingStateActive {
            usernameField.becomeFirstResponder()
        }
    }

    /// Configure the site header.
    ///
    @objc func configureHeader() {
        if let siteInfo = loginFields.meta.siteInfo {
            configureBlogDetailHeaderView(siteInfo: siteInfo)
        } else {
            configureSiteAddressHeader()
        }
    }

    /// Configure the site header to show the BlogDetailsHeaderView
    ///
    func configureBlogDetailHeaderView(siteInfo: WordPressComSiteInfo) {
        let siteAddress = sanitizedSiteAddress(siteAddress: siteInfo.url)
        siteHeaderView.title = siteInfo.name
        siteHeaderView.subtitle = NSURL.idnDecodedURL(siteAddress)
        siteHeaderView.subtitleIsHidden = false

        siteHeaderView.blavatarBorderIsHidden = false
        siteHeaderView.downloadBlavatar(at: siteInfo.icon)
    }

    /// Configure the site header to show the site address label.
    ///
    @objc func configureSiteAddressHeader() {
        siteHeaderView.title = sanitizedSiteAddress(siteAddress: loginFields.siteAddress)
        siteHeaderView.subtitleIsHidden = true

        siteHeaderView.blavatarBorderIsHidden = true
        siteHeaderView.blavatarImage = .linkFieldImage
    }

    /// Sanitize and format the site address we show to users.
    ///
    @objc func sanitizedSiteAddress(siteAddress: String) -> String {
        let baseSiteUrl = WordPressAuthenticator.baseSiteURL(string: siteAddress) as NSString
        if let str = baseSiteUrl.components(separatedBy: "://").last {
            return str
        }
        return siteAddress
    }

    // MARK: - Instance Methods

    /// Validates what is entered in the various form fields and, if valid,
    /// proceeds with the submit action.
    ///
    @objc func validateForm() {
        validateFormAndLogin()
    }

    // MARK: - Actions

    @IBAction func handleTextFieldDidChange(_ sender: UITextField) {
        loginFields.username = usernameField.nonNilTrimmedText()
        loginFields.password = passwordField.nonNilTrimmedText()

        configureForgotPasswordButton()
        configureSubmitButton(animating: false)
    }

    @IBAction func handleSubmitButtonTapped(_ sender: UIButton) {
        validateForm()
    }

    @IBAction func handleForgotPasswordButtonTapped(_ sender: UIButton) {
        WordPressAuthenticator.openForgotPasswordURL(loginFields)
        WordPressAuthenticator.track(.loginForgotPasswordClicked)
    }

    // MARK: - Keyboard Notifications

    @objc func handleKeyboardWillShow(_ notification: Foundation.Notification) {
        keyboardWillShow(notification)
    }

    @objc func handleKeyboardWillHide(_ notification: Foundation.Notification) {
        keyboardWillHide(notification)
    }
}

extension LoginUsernamePasswordViewController {

    func displayLoginMessage(_ message: String) {
        configureForgotPasswordButton()
    }

    override func displayRemoteError(_ error: Error) {
        displayLoginMessage("")
        configureViewLoading(false)
        let err = error as NSError
        if err.code == 403 {
            displayError(message: NSLocalizedString("It looks like this username/password isn't associated with this site.", comment: "An error message shown during log in when the username or password is incorrect."))
        } else {
            displayError(error, sourceTag: sourceTag)
        }
    }
}

extension LoginUsernamePasswordViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            validateForm()
        }
        return true
    }
}
