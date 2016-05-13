import UIKit
import SVProgressHUD
import WordPressComAnalytics
import WordPressShared

/// Provides a form and functionality for entering a two factor auth code and
/// signing into WordPress.com
///
@objc class Signin2FAViewController : NUXAbstractViewController, SigninWPComSyncHandler, SigninKeyboardResponder {

    @IBOutlet weak var verificationCodeField: UITextField!
    @IBOutlet weak var sendCodeButton: UIButton!
    @IBOutlet weak var submitButton: NUXSubmitButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet var bottomContentConstraint: NSLayoutConstraint!
    @IBOutlet var verticalCenterConstraint: NSLayoutConstraint!

    lazy private var loginFacade: LoginFacade = {
        let facade = LoginFacade()
        facade.delegate = self
        return facade
    }()


    /// A convenience method for obtaining an instance of the controller from a storyboard.
    ///
    /// - Parameter loginFields: A LoginFields instance containing any prefilled credentials.
    ///
    class func controller(loginFields: LoginFields) -> Signin2FAViewController {
        let storyboard = UIStoryboard(name: "Signin", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("Signin2FAViewController") as! Signin2FAViewController
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


    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        configureViewForEditingIfNeeded()
    }


    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        registerForKeyboardEvents(keyboardWillShowAction: #selector(SigninEmailViewController.handleKeyboardWillShow(_:)),
                                  keyboardWillHideAction: #selector(SigninEmailViewController.handleKeyboardWillHide(_:)))

    }


    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterForKeyboardEvents()

        // Multifactor codes are time sensitive, so clear the stored code if the
        // user dismisses the view. They'll need to reentered it upon return.
        loginFields.multifactorCode = ""
        verificationCodeField.text = ""
    }


    // MARK: Configuration Methods


    /// Assigns localized strings to various UIControl defined in the storyboard.
    ///
    func localizeControls() {
        verificationCodeField.placeholder = NSLocalizedString("Verification code", comment: "two factor code placeholder")

        let submitButtonTitle = NSLocalizedString("Verify", comment: "Title of a button. The text should be uppercase.").localizedUppercaseString
        submitButton.setTitle(submitButtonTitle, forState: .Normal)
        submitButton.setTitle(submitButtonTitle, forState: .Highlighted)
    }


    /// Configures the appearance of the button to request a 2fa code be sent via SMS.
    ///
    func configureSendCodeButtonText() {
        // Text: Verification Code SMS
        let string = NSLocalizedString("Enter the code on your authenticator app or <u>send the code via text message</u>.",
                                       comment: "Message displayed when a verification code is needed")

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .Center

        let attributes: StyledHTMLAttributes = [ .BodyAttribute: [ NSFontAttributeName: UIFont.systemFontOfSize(14),
                                                                   NSForegroundColorAttributeName: UIColor.whiteColor(),
                                                                   NSParagraphStyleAttributeName: paragraphStyle ]]

        let attributedCode = NSAttributedString.attributedStringWithHTML(string, attributes: attributes)
        let attributedCodeHighlighted = attributedCode.mutableCopy() as! NSMutableAttributedString
        attributedCodeHighlighted.applyForegroundColor(WPNUXUtility.confirmationLabelColor())

        if let titleLabel = sendCodeButton.titleLabel {
            titleLabel.lineBreakMode = .ByWordWrapping
            titleLabel.textAlignment = .Center
            titleLabel.numberOfLines = 3
        }

        sendCodeButton.setAttributedTitle(attributedCode, forState: .Normal)
        sendCodeButton.setAttributedTitle(attributedCodeHighlighted, forState: .Highlighted)
    }


    /// Displays the specified text in the status label.
    ///
    /// - Parameter message: The text to display in the label.
    ///
    func configureStatusLabel(message: String) {
        statusLabel.text = message

        sendCodeButton.hidden = !message.isEmpty
    }


    /// Configures the appearance and state of the submit button.
    ///
    func configureSubmitButton(animating animating: Bool) {
        submitButton.showActivityIndicator(animating)

        submitButton.enabled = (
            !animating &&
            !loginFields.multifactorCode.isEmpty
        )
    }


    /// Configure the view's loading state.
    ///
    /// - Parameter loading: True if the form should be configured to a "loading" state.
    ///
    func configureViewLoading(loading: Bool) {
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
            WPError.showAlertWithTitle(NSLocalizedString("Error", comment: "Title of an error message"),
                                       message: NSLocalizedString("Please fill out all the fields", comment: "A short prompt asking the user to properly fill out all login fields."),
                                       withSupportButton: false)

            return
        }

        configureViewLoading(true)

        loginFacade.signInWithLoginFields(loginFields)
    }


    /// Update safari stored credentials. Call after a successful sign in.
    ///
    func updateSafariCredentialsIfNeeded() {
        SigninHelpers.updateSafariCredentialsIfNeeded(loginFields)
    }


    // MARK: - Actions


    @IBAction func handleTextFieldDidChange(sender: UITextField) {
        loginFields.multifactorCode = verificationCodeField.nonNilTrimmedText()

        configureSubmitButton(animating: false)
    }


    @IBAction func handleSubmitForm() {
        validateForm()
    }


    @IBAction func handleSubmitButtonTapped(sender: UIButton) {
        validateForm()
    }


    @IBAction func handleSendVerificationButtonTapped(sender: UIButton) {
        let message = NSLocalizedString("SMS Sent", comment: "One Time Code has been sent via SMS")
        SVProgressHUD.showSuccessWithStatus(message)

        loginFacade.requestOneTimeCodeWithLoginFields(loginFields)
    }


    // MARK: - Keyboard Notifications


    func handleKeyboardWillShow(notification: NSNotification) {
        keyboardWillShow(notification)
    }


    func handleKeyboardWillHide(notification: NSNotification) {
        keyboardWillHide(notification)
    }
}


extension Signin2FAViewController: LoginFacadeDelegate {

    func finishedLoginWithUsername(username: String!, authToken: String!, requiredMultifactorCode: Bool) {
        syncWPCom(username, authToken: authToken, requiredMultifactor: requiredMultifactorCode)
    }


    func displayLoginMessage(message: String!) {
        configureStatusLabel(message)
    }


    func displayRemoteError(error: NSError!) {
        configureStatusLabel("")
        configureViewLoading(false)
        displayError(error)
    }
}
