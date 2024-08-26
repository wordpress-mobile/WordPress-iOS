import UIKit
import SVProgressHUD
import WordPressShared
import WordPressKit

/// Provides a form and functionality for entering a two factor auth code and
/// signing into WordPress.com
///
class Login2FAViewController: LoginViewController, NUXKeyboardResponder, UITextFieldDelegate {

    @IBOutlet weak var verificationCodeField: LoginTextField!
    @IBOutlet weak var sendCodeButton: UIButton!
    @IBOutlet var bottomContentConstraint: NSLayoutConstraint?
    @IBOutlet var verticalCenterConstraint: NSLayoutConstraint?

    private var pasteboardChangeCountBeforeBackground: Int = 0
    override var sourceTag: WordPressSupportSourceTag {
        get {
            return .login2FA
        }
    }

    private enum Constants {
        static let headsUpDismissDelay = TimeInterval(1)
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        localizeControls()
        configureTextFields()
        configureSubmitButton(animating: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configureViewForEditingIfNeeded()
        styleSendCodeButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        registerForKeyboardEvents(keyboardWillShowAction: #selector(handleKeyboardWillShow(_:)),
                                  keyboardWillHideAction: #selector(handleKeyboardWillHide(_:)))

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(applicationBecameInactive), name: UIApplication.willResignActiveNotification, object: nil)
        nc.addObserver(self, selector: #selector(applicationBecameActive), name: UIApplication.didBecomeActiveNotification, object: nil)

        WordPressAuthenticator.track(.loginTwoFactorFormViewed)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterForKeyboardEvents()
        NotificationCenter.default.removeObserver(self)

        // Multifactor codes are time sensitive, so clear the stored code if the
        // user dismisses the view. They'll need to reentered it upon return.
        loginFields.multifactorCode = ""
        verificationCodeField.text = ""
    }

    // MARK: Dynamic Type
    override func didChangePreferredContentSize() {
        super.didChangePreferredContentSize()
        styleSendCodeButton()
    }

    private func styleSendCodeButton() {
        sendCodeButton.titleLabel?.adjustsFontForContentSizeCategory = true
        sendCodeButton.titleLabel?.adjustsFontSizeToFitWidth = true
        WPStyleGuide.configureTextButton(sendCodeButton)
    }

    // MARK: Configuration Methods

    /// Assigns localized strings to various UIControl defined in the storyboard.
    ///
    @objc func localizeControls() {
        instructionLabel?.text = NSLocalizedString("Almost there! Please enter the verification code from your authenticator app.", comment: "Instructions for users with two-factor authentication enabled.")

        verificationCodeField.placeholder = NSLocalizedString("Verification code", comment: "two factor code placeholder")

        let submitButtonTitle = NSLocalizedString("Next", comment: "Title of a button.").localizedCapitalized
        submitButton?.setTitle(submitButtonTitle, for: .normal)
        submitButton?.setTitle(submitButtonTitle, for: .highlighted)

        sendCodeButton.setTitle(NSLocalizedString("Text me a code instead", comment: "Button title"),
                                for: .normal)
        sendCodeButton.titleLabel?.numberOfLines = 0
    }

    /// configures the text fields
    ///
    @objc func configureTextFields() {
        verificationCodeField.contentInsets = WPStyleGuide.edgeInsetForLoginTextFields()
        verificationCodeField.textContentType = .oneTimeCode

    }

    /// Configures the appearance and state of the submit button.
    ///
    override func configureSubmitButton(animating: Bool) {
        submitButton?.showActivityIndicator(animating)

        let isNumeric = loginFields.multifactorCode.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
        let isValidLength = SocialLogin2FANonceInfo.TwoFactorTypeLengths(rawValue: loginFields.multifactorCode.count) != nil

        submitButton?.isEnabled = (
            !animating &&
            isNumeric &&
            isValidLength
        )
    }

    /// Configure the view's loading state.
    ///
    /// - Parameter loading: True if the form should be configured to a "loading" state.
    ///
    override func configureViewLoading(_ loading: Bool) {
        verificationCodeField.enablesReturnKeyAutomatically = !loading

        configureSubmitButton(animating: loading)
        navigationItem.hidesBackButton = loading
    }

    /// Configure the view for an editing state. Should only be called from viewWillAppear
    /// as this method skips animating any change in height.
    ///
    @objc func configureViewForEditingIfNeeded() {
        // Check the helper to determine whether an editiing state should be assumed.
        adjustViewForKeyboard(SigninEditingState.signinEditingStateActive)
        if SigninEditingState.signinEditingStateActive {
            verificationCodeField.becomeFirstResponder()
        }
    }

    // MARK: - Instance Methods

    /// Validates what is entered in the various form fields and, if valid,
    /// proceeds with the submit action.
    ///
    @objc func validateForm() {
        if let nonce = loginFields.nonceInfo {
            loginWithNonce(info: nonce)
            return
        }
        validateFormAndLogin()
    }

    private func loginWithNonce(info nonceInfo: SocialLogin2FANonceInfo) {
        let code = loginFields.multifactorCode
        let (authType, nonce) = nonceInfo.authTypeAndNonce(for: code)
        loginFacade.loginToWordPressDotCom(withUser: loginFields.nonceUserID, authType: authType, twoStepCode: code, twoStepNonce: nonce)
    }

    func finishedLogin(withNonceAuthToken authToken: String) {
        let wpcom = WordPressComCredentials(authToken: authToken, isJetpackLogin: isJetpackLogin, multifactor: true, siteURL: loginFields.siteAddress)
        let credentials = AuthenticatorCredentials(wpcom: wpcom)
        syncWPComAndPresentEpilogue(credentials: credentials)

        // This stat is part of a funnel that provides critical information.  Please
        // consult with your lead before removing this event.
        WordPressAuthenticator.track(.signedIn)

        var properties = [AnyHashable: Any]()
        if let service = loginFields.meta.socialService?.rawValue {
            properties["source"] = service
        }

        WordPressAuthenticator.track(.loginSocialSuccess, properties: properties)
    }

    /// Only allow digits in the 2FA text field
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString: String) -> Bool {
        guard let fieldText = textField.text as NSString? else {
            return true
        }
        let resultString = fieldText.replacingCharacters(in: range, with: replacementString)

        switch isValidCode(code: resultString) {
        case .valid(let cleanedCode):
            displayError(message: "")

            // because the string was stripped of whitespace, we can't return true and we update the textfield ourselves
            textField.text = cleanedCode
            handleTextFieldDidChange(textField)
        case .invalid(nonNumbers: true):
            displayError(message: NSLocalizedString("A verification code will only contain numbers.", comment: "Shown when a user types a non-number into the two factor field."))
        default:
            if let pasteString = UIPasteboard.general.string, pasteString == replacementString {
                displayError(message: NSLocalizedString("That doesn't appear to be a valid verification code.", comment: "Shown when a user pastes a code into the two factor field that contains letters or is the wrong length"))
            }
        }

        return false
    }

    private enum CodeValidation {
        case invalid(nonNumbers: Bool)
        case valid(String)
    }

    private func isValidCode(code: String) -> CodeValidation {
        let codeStripped = code.components(separatedBy: .whitespacesAndNewlines).joined()
        let allowedCharacters = CharacterSet.decimalDigits
        let resultCharacterSet = CharacterSet(charactersIn: codeStripped)
        let isOnlyNumbers = allowedCharacters.isSuperset(of: resultCharacterSet)
        let isShortEnough = codeStripped.count <= SocialLogin2FANonceInfo.TwoFactorTypeLengths.backup.rawValue

        if isOnlyNumbers && isShortEnough {
            return .valid(codeStripped)
        } else if isOnlyNumbers {
            return .invalid(nonNumbers: false)
        } else {
            return .invalid(nonNumbers: true)
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        validateForm()
        return false
    }

    @IBAction func handleTextFieldDidChange(_ sender: UITextField) {
        loginFields.multifactorCode = verificationCodeField.nonNilTrimmedText()
        configureSubmitButton(animating: false)
    }

    // MARK: - Actions

    @IBAction func handleSubmitForm() {
        validateForm()
    }

    @IBAction func handleSubmitButtonTapped(_ sender: UIButton) {
        tracker.track(click: .submit)

        validateForm()
    }

    @IBAction func handleSendVerificationButtonTapped(_ sender: UIButton) {
        self.tracker.track(click: .sendCodeWithText)

        let message = NSLocalizedString("SMS Sent", comment: "One Time Code has been sent via SMS")
        SVProgressHUD.showSuccess(withStatus: message)
        SVProgressHUD.dismiss(withDelay: Constants.headsUpDismissDelay)

        if let _ = loginFields.nonceInfo {
            // social login
            loginFacade.requestSocial2FACode(with: loginFields)
        } else {
            loginFacade.requestOneTimeCode(with: loginFields)
        }
    }

    // MARK: - Handle application state changes.

    @objc func applicationBecameInactive() {
        pasteboardChangeCountBeforeBackground = UIPasteboard.general.changeCount
    }

    @objc func applicationBecameActive() {
        let emptyField = verificationCodeField.text?.isEmpty ?? true
        guard emptyField,
            pasteboardChangeCountBeforeBackground != UIPasteboard.general.changeCount else {
                return
        }

        UIPasteboard.general.detectAuthenticatorCode { [weak self] result in
            switch result {
                case .success(let authenticatorCode):
                    self?.handle(code: authenticatorCode)
                case .failure:
                    break
            }
        }
    }

    private func handle(code: String) {
        switch isValidCode(code: code) {
        case .valid(let cleanedCode):
            displayError(message: "")
            verificationCodeField.text = cleanedCode
            handleTextFieldDidChange(verificationCodeField)
        default:
            break
        }
    }

    // MARK: - Keyboard Notifications

    @objc func handleKeyboardWillShow(_ notification: Foundation.Notification) {
        keyboardWillShow(notification)
    }

    @objc func handleKeyboardWillHide(_ notification: Foundation.Notification) {
        keyboardWillHide(notification)
    }
}

extension Login2FAViewController {

    override func displayRemoteError(_ error: Error) {
        displayError(message: "")

        configureViewLoading(false)
        let bad2FAMessage = NSLocalizedString("Whoops, that's not a valid two-factor verification code. Double-check your code and try again!", comment: "Error message shown when an incorrect two factor code is provided.")
        if (error as? WordPressComOAuthError)?.authenticationFailureKind == .invalidOneTimePassword {
            // Invalid verification code.
            displayError(message: bad2FAMessage)
        } else if case let .endpointError(authenticationFailure) = (error as? WordPressComOAuthError), authenticationFailure.kind == .invalidTwoStepCode {
            // Invalid 2FA during social login
            if let newNonce = authenticationFailure.newNonce {
                loginFields.nonceInfo?.updateNonce(with: newNonce)
            }
            displayError(message: bad2FAMessage)
        } else {
            displayError(error, sourceTag: sourceTag)
        }
    }
}
