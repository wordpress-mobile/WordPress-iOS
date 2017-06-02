import UIKit
import SVProgressHUD
import WordPressComAnalytics
import WordPressShared

/// Provides a form and functionality for entering a two factor auth code and
/// signing into WordPress.com
///
@objc class Signin2FAViewController: NUXAbstractViewController, SigninWPComSyncHandler, SigninKeyboardResponder {

    @IBOutlet weak var verificationCodeField: UITextField!
    @IBOutlet weak var sendCodeButton: UIButton!
    @IBOutlet weak var submitButton: NUXSubmitButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet var bottomContentConstraint: NSLayoutConstraint?
    @IBOutlet var verticalCenterConstraint: NSLayoutConstraint?
    var pasteboardBeforeBackground: String? = nil

    lazy fileprivate var loginFacade: LoginFacade = {
        let facade = LoginFacade()
        facade.delegate = self
        return facade
    }()

    override var sourceTag: SupportSourceTag {
        get {
            return .wpComLogin
        }
    }


    /// A convenience method for obtaining an instance of the controller from a storyboard.
    ///
    /// - Parameter loginFields: A LoginFields instance containing any prefilled credentials.
    ///
    class func controller(_ loginFields: LoginFields) -> Signin2FAViewController {
        let storyboard = UIStoryboard(name: "Signin", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "Signin2FAViewController") as! Signin2FAViewController
        controller.loginFields = loginFields
        return controller
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        localizeControls()
        configureSendCodeButtonText()
        configureStatusLabel("")
        configureSubmitButton(animating: false)
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configureViewForEditingIfNeeded()
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        registerForKeyboardEvents(keyboardWillShowAction: #selector(SigninEmailViewController.handleKeyboardWillShow(_:)),
                                  keyboardWillHideAction: #selector(SigninEmailViewController.handleKeyboardWillHide(_:)))

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(applicationBecameInactive), name: .UIApplicationWillResignActive, object: nil)
        nc.addObserver(self, selector: #selector(applicationBecameActive), name: .UIApplicationDidBecomeActive, object: nil)
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


    // MARK: Configuration Methods


    /// Assigns localized strings to various UIControl defined in the storyboard.
    ///
    func localizeControls() {
        verificationCodeField.placeholder = NSLocalizedString("Verification code", comment: "two factor code placeholder")

        let submitButtonTitle = NSLocalizedString("Verify", comment: "Title of a button. The text should be uppercase.").localizedUppercase
        submitButton.setTitle(submitButtonTitle, for: UIControlState())
        submitButton.setTitle(submitButtonTitle, for: .highlighted)
    }


    /// Configures the appearance of the button to request a 2fa code be sent via SMS.
    ///
    func configureSendCodeButtonText() {
        // Text: Verification Code SMS
        let string = NSLocalizedString("Enter the code on your authenticator app or <u>send the code via text message</u>.",
                                       comment: "Message displayed when a verification code is needed")

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: StyledHTMLAttributes = [ .BodyAttribute: [ NSFontAttributeName: UIFont.systemFont(ofSize: 14),
                                                                   NSForegroundColorAttributeName: UIColor.white,
                                                                   NSParagraphStyleAttributeName: paragraphStyle ]]

        let attributedCode = NSAttributedString.attributedStringWithHTML(string, attributes: attributes)
        let attributedCodeHighlighted = attributedCode.mutableCopy() as! NSMutableAttributedString
        attributedCodeHighlighted.applyForegroundColor(WPNUXUtility.confirmationLabelColor())

        if let titleLabel = sendCodeButton.titleLabel {
            titleLabel.lineBreakMode = .byWordWrapping
            titleLabel.textAlignment = .center
            titleLabel.numberOfLines = 3
        }

        sendCodeButton.setAttributedTitle(attributedCode, for: UIControlState())
        sendCodeButton.setAttributedTitle(attributedCodeHighlighted, for: .highlighted)
    }


    /// Displays the specified text in the status label.
    ///
    /// - Parameter message: The text to display in the label.
    ///
    func configureStatusLabel(_ message: String) {
        statusLabel.text = message

        sendCodeButton.isHidden = !message.isEmpty
    }


    /// Configures the appearance and state of the submit button.
    ///
    func configureSubmitButton(animating: Bool) {
        submitButton.showActivityIndicator(animating)

        submitButton.isEnabled = (
            !animating &&
            !loginFields.multifactorCode.isEmpty
        )
    }


    /// Configure the view's loading state.
    ///
    /// - Parameter loading: True if the form should be configured to a "loading" state.
    ///
    func configureViewLoading(_ loading: Bool) {
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


    /// Validates what is entered in the various form fields and, if valid,
    /// proceeds with the submit action.
    ///
    func validateForm() {
        view.endEditing(true)

        // Is everything filled out?
        if loginFields.multifactorCode.isEmpty {
            WPError.showAlert(withTitle: NSLocalizedString("Error", comment: "Title of an error message"),
                                       message: NSLocalizedString("Please fill out all the fields", comment: "A short prompt asking the user to properly fill out all login fields."),
                                       withSupportButton: false)

            return
        }

        configureViewLoading(true)

        loginFacade.signIn(with: loginFields)
    }


    /// Update safari stored credentials. Call after a successful sign in.
    ///
    func updateSafariCredentialsIfNeeded() {
        SigninHelpers.updateSafariCredentialsIfNeeded(loginFields)
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


    // MARK: - Keyboard Notifications


    func handleKeyboardWillShow(_ notification: Foundation.Notification) {
        keyboardWillShow(notification)
    }


    func handleKeyboardWillHide(_ notification: Foundation.Notification) {
        keyboardWillHide(notification)
    }
}


extension Signin2FAViewController: LoginFacadeDelegate {

    func finishedLogin(withUsername username: String!, authToken: String!, requiredMultifactorCode: Bool) {
        syncWPCom(username, authToken: authToken, requiredMultifactor: requiredMultifactorCode)
    }


    func displayLoginMessage(_ message: String!) {
        configureStatusLabel(message)
    }


    func displayRemoteError(_ error: Error!) {
        configureStatusLabel("")
        configureViewLoading(false)
        displayError(error as NSError, sourceTag: sourceTag)
    }
}
