import UIKit
import SVProgressHUD
import WordPressShared

/// Provides a form and functionality for entering a two factor auth code and
/// signing into WordPress.com
///
class Login2FAViewController: LoginViewController, SigninKeyboardResponder {
    @IBOutlet weak var verificationCodeField: LoginTextField!
    @IBOutlet weak var sendCodeButton: UIButton!
    @IBOutlet var bottomContentConstraint: NSLayoutConstraint?
    @IBOutlet var verticalCenterConstraint: NSLayoutConstraint?
    var pasteboardBeforeBackground: String? = nil

    override var sourceTag: SupportSourceTag {
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

        WPAppAnalytics.track(.loginTwoFactorFormViewed)
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


    /// let the storyboard's style stay
    ///
    override func setupStyles() {}


    /// Assigns localized strings to various UIControl defined in the storyboard.
    ///
    func localizeControls() {
        instructionLabel?.text = NSLocalizedString("Almost there! Please enter the verification code from your authenticator app.", comment: "Instructions for users with two-factor authentication enabled.")

        verificationCodeField.placeholder = NSLocalizedString("Verification code", comment: "two factor code placeholder")

        let submitButtonTitle = NSLocalizedString("Next", comment: "Title of a button.").localizedCapitalized
        submitButton?.setTitle(submitButtonTitle, for: UIControlState())
        submitButton?.setTitle(submitButtonTitle, for: .highlighted)

        sendCodeButton.setTitle(NSLocalizedString("Text me a code instead", comment: "Button title"),
                                for: .normal)
        sendCodeButton.titleLabel?.numberOfLines = 0
    }


    func configureTextFields() {
        verificationCodeField.textInsets = WPStyleGuide.edgeInsetForLoginTextFields()
    }


    /// Configures the appearance and state of the submit button.
    ///
    override func configureSubmitButton(animating: Bool) {
        submitButton?.showActivityIndicator(animating)

        submitButton?.isEnabled = (
            !animating &&
                !loginFields.multifactorCode.isEmpty
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
    func configureViewForEditingIfNeeded() {
        // Check the helper to determine whether an editiing state should be assumed.
        adjustViewForKeyboard(SigninEditingState.signinEditingStateActive)
        if SigninEditingState.signinEditingStateActive {
            verificationCodeField.becomeFirstResponder()
        }
    }


    // MARK: - Instance Methods


    func showEpilogue() {
        performSegue(withIdentifier: .showEpilogue, sender: self)
    }


    /// Validates what is entered in the various form fields and, if valid,
    /// proceeds with the submit action.
    ///
    func validateForm() {
        validateFormAndLogin()
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

        loginFacade.requestOneTimeCode(with: loginFields)
    }



    // MARK: - Handle application state changes.


    func applicationBecameInactive() {
        pasteboardBeforeBackground = UIPasteboard.general.string
    }


    func applicationBecameActive() {
        let emptyField = verificationCodeField.text?.isEmpty ?? true
        guard emptyField,
            let pasteString = UIPasteboard.general.string,
            pasteString != pasteboardBeforeBackground else {
                return
        }
        let isNumeric = pasteString.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
        guard isNumeric && pasteString.characters.count == 6 else {
            return
        }
        verificationCodeField.text = pasteString
        handleTextFieldDidChange(verificationCodeField)
    }


    // MARK: - Keyboard Notifications


    func handleKeyboardWillShow(_ notification: Foundation.Notification) {
        keyboardWillShow(notification)
    }


    func handleKeyboardWillHide(_ notification: Foundation.Notification) {
        keyboardWillHide(notification)
    }
}


extension Login2FAViewController {

    override func displayRemoteError(_ error: Error!) {
        displayError(message: "")

        configureViewLoading(false)
        let err = error as NSError
        if (err.domain == "WordPressComOAuthError" && err.code == WordPressComOAuthError.invalidOneTimePassword.rawValue) {
            // Invalid verification code.
            displayError(message: NSLocalizedString("Whoops, that's not a valid two-factor verification code. Double-check your code and try again!",
                                                    comment: "Error message shown when an incorrect two factor code is provided."))
        } else {
            displayError(error as NSError, sourceTag: sourceTag)
        }
    }
}
