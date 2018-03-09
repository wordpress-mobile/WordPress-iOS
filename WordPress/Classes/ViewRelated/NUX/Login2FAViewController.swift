import UIKit
import SVProgressHUD
import WordPressShared
import GoogleSignIn

/// Provides a form and functionality for entering a two factor auth code and
/// signing into WordPress.com
///
class Login2FAViewController: LoginViewController, NUXKeyboardResponder, UITextFieldDelegate {

    @IBOutlet weak var verificationCodeField: LoginTextField!
    @IBOutlet weak var sendCodeButton: UIButton!
    @IBOutlet var bottomContentConstraint: NSLayoutConstraint?
    @IBOutlet var verticalCenterConstraint: NSLayoutConstraint?
    @objc var pasteboardBeforeBackground: String? = nil
    override var sourceTag: WordPressSupportSourceTag {
        get {
            return .login2FA
        }
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
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        registerForKeyboardEvents(keyboardWillShowAction: #selector(handleKeyboardWillShow(_:)),
                                  keyboardWillHideAction: #selector(handleKeyboardWillHide(_:)))

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(applicationBecameInactive), name: .UIApplicationWillResignActive, object: nil)
        nc.addObserver(self, selector: #selector(applicationBecameActive), name: .UIApplicationDidBecomeActive, object: nil)

        WordPressAuthenticator.post(event: .loginTwoFactorFormViewed)
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


    // MARK: Configuration Methods


    /// Assigns localized strings to various UIControl defined in the storyboard.
    ///
    @objc func localizeControls() {
        instructionLabel?.text = NSLocalizedString("Almost there! Please enter the verification code from your authenticator app.", comment: "Instructions for users with two-factor authentication enabled.")

        verificationCodeField.placeholder = NSLocalizedString("Verification code", comment: "two factor code placeholder")

        let submitButtonTitle = NSLocalizedString("Next", comment: "Title of a button.").localizedCapitalized
        submitButton?.setTitle(submitButtonTitle, for: UIControlState())
        submitButton?.setTitle(submitButtonTitle, for: .highlighted)

        sendCodeButton.setTitle(NSLocalizedString("Text me a code instead", comment: "Button title"),
                                for: .normal)
        sendCodeButton.titleLabel?.numberOfLines = 0
    }

    /// configures the text fields
    ///
    @objc func configureTextFields() {
        verificationCodeField.contentInsets = WPStyleGuide.edgeInsetForLoginTextFields()
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


    @objc func showEpilogue() {
        performSegue(withIdentifier: .showEpilogue, sender: self)
    }


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

    func finishedLogin(withNonceAuthToken authToken: String!) {
        let username = loginFields.username
        syncWPCom(username, authToken: authToken, requiredMultifactor: true)
        // Disconnect now that we're done with Google.
        GIDSignIn.sharedInstance().disconnect()
        WordPressAuthenticator.post(event: .loginSocialSuccess)
    }

    /// Only allow digits in the 2FA text field
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString: String) -> Bool {
        let allowedCharacters = CharacterSet.decimalDigits
        let characterSet = CharacterSet(charactersIn: replacementString)
        let isOnlyNumbers = allowedCharacters.isSuperset(of: characterSet)
        let isShortEnough = (textField.text?.count ?? 0) + replacementString.count <= SocialLogin2FANonceInfo.TwoFactorTypeLengths.backup.rawValue

        if isOnlyNumbers && isShortEnough {
            displayError(message: "")
            return true
        }

        if let pasteString = UIPasteboard.general.string, pasteString == replacementString {
            displayError(message: NSLocalizedString("That doesn't appear to be a valid verification code.", comment: "Shown when a user pastes a code into the two factor field that contains letters or is the wrong length"))
        } else if !isOnlyNumbers {
            displayError(message: NSLocalizedString("A verification code will only contain numbers.", comment: "Shown when a user types a non-number into the two factor field."))
        }

        return false
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        validateForm()
        return false
    }


    // MARK: - Actions

    @IBAction func handleTextFieldDidChange(_ sender: UITextField) {
        loginFields.multifactorCode = verificationCodeField.nonNilTrimmedText()

        configureSubmitButton(animating: false)
    }


    @IBAction func handleSubmitForm() {
        validateForm()
    }


    @IBAction func handleSubmitButtonTapped(_ sender: UIButton) {
        validateForm()
    }


    @IBAction func handleSendVerificationButtonTapped(_ sender: UIButton) {
        let message = NSLocalizedString("SMS Sent", comment: "One Time Code has been sent via SMS")
        SVProgressHUD.showDismissibleSuccess(withStatus: message)

        if let _ = loginFields.nonceInfo {
            // social login
            loginFacade.requestSocial2FACode(with: loginFields)
        } else {
            loginFacade.requestOneTimeCode(with: loginFields)
        }
    }



    // MARK: - Handle application state changes.


    @objc func applicationBecameInactive() {
        pasteboardBeforeBackground = UIPasteboard.general.string
    }


    @objc func applicationBecameActive() {
        let emptyField = verificationCodeField.text?.isEmpty ?? true
        guard emptyField,
            let pasteString = UIPasteboard.general.string,
            pasteString != pasteboardBeforeBackground else {
                return
        }
        let isNumeric = pasteString.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
        guard isNumeric, let _ = SocialLogin2FANonceInfo.TwoFactorTypeLengths(rawValue: pasteString.count) else {
            return
        }
        displayError(message: "")
        verificationCodeField.text = pasteString
        handleTextFieldDidChange(verificationCodeField)
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

    override func displayRemoteError(_ error: Error!) {
        displayError(message: "")

        configureViewLoading(false)
        let err = error as NSError
        let bad2FAMessage = NSLocalizedString("Whoops, that's not a valid two-factor verification code. Double-check your code and try again!", comment: "Error message shown when an incorrect two factor code is provided.")
        if err.domain == "WordPressComOAuthError" && err.code == WordPressComOAuthError.invalidOneTimePassword.rawValue {
            // Invalid verification code.
            displayError(message: bad2FAMessage)
        } else if err.domain == "WordPressComOAuthError" && err.code == WordPressComOAuthError.invalidTwoStepCode.rawValue {
            // Invalid 2FA during social login
            if let newNonce = (error as NSError).userInfo[WordPressComOAuthClient.WordPressComOAuthErrorNewNonceKey] as? String {
                loginFields.nonceInfo?.updateNonce(with: newNonce)
            }
            displayError(message: bad2FAMessage)
        } else {
            displayError(error as NSError, sourceTag: sourceTag)
        }
    }
}
