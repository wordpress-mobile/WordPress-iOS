import UIKit
import SVProgressHUD
import WordPressComAnalytics
import WordPressShared

///
///
class Signin2FAViewController : NUXAbstractViewController, SigninWPComSyncHandler
{

    @IBOutlet weak var verificationCodeField: UITextField!
    @IBOutlet weak var sendCodeButton: UIButton!
    @IBOutlet weak var submitButton: WPNUXMainButton!
    @IBOutlet weak var statusLabel: UILabel!

    lazy private var loginFacade: LoginFacade = {
        let facade = LoginFacade()
        facade.delegate = self
        return facade
    }()

    lazy var blogSyncFacade = BlogSyncFacade()
    lazy var accountServiceFacade = AccountServiceFacade()


    ///
    ///
    class func controller(loginFields: LoginFields) -> Signin2FAViewController {
        let storyboard = UIStoryboard(name: "Signin", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("Signin2FAViewController") as! Signin2FAViewController
        controller.loginFields = loginFields
        return controller
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        configureSendCodeButtonText()
        configureStatusMessage("")
    }


    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        verificationCodeField.becomeFirstResponder()
    }


    // MARK: Configuration Methods


    /// Configures the appearance of the button to request a 2fa code be sent via SMS.
    ///
    func configureSendCodeButtonText() {
        // Text: Verification Code SMS
        let string = NSLocalizedString("Enter the code on your authenticator app or <u>send the code via text message</u>.",
                                       comment: "Message displayed when a verification code is needed")
        let options = [
            NSFontAttributeName : WPNUXUtility.confirmationLabelFont(),
            NSForegroundColorAttributeName: UIColor.whiteColor(),
            NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType
        ]

        let attributedCode = try! NSMutableAttributedString(data: string.dataUsingEncoding(NSUTF8StringEncoding)!,
                                                            options: options,
                                                            documentAttributes: nil)

        let attributedCodeHighlighted = attributedCode.mutableCopy() as! NSMutableAttributedString
        attributedCodeHighlighted.applyForegroundColor(WPNUXUtility.confirmationLabelColor())

        sendCodeButton.titleLabel!.lineBreakMode = .ByWordWrapping
        sendCodeButton.titleLabel!.textAlignment = .Center
        sendCodeButton.titleLabel!.numberOfLines = 3
        sendCodeButton.setAttributedTitle(attributedCode, forState: .Normal)
        sendCodeButton.setAttributedTitle(attributedCodeHighlighted, forState: .Highlighted)
    }


    /// Displays the specified text in the status label.
    ///
    /// - Parameters:
    ///     - message: The text to display in the label.
    ///
    func configureStatusMessage(message: String) {
        statusLabel.text = message
    }


    /// Configures the appearance and state of the submit button.
    ///
    func configureSubmitButton(animating: Bool) {
        submitButton.showActivityIndicator(animating)

        submitButton.enabled = (
            !animating &&
            !loginFields.multifactorCode.isEmpty
        )
    }


    /// Sets the view's state to loading or not loading.
    ///
    /// - Parameters:
    ///     - loading: True if the form should be configured to a "loading" state.
    ///
    func configureLoading(loading: Bool) {
        verificationCodeField.enablesReturnKeyAutomatically = !loading

        configureSubmitButton(loading)
    }


    // MARK: - Instance Methods


    /// Validates what is entered in the various form fields and, if valid,
    /// proceeds with the submit action.
    ///
    func validateForm() {
        view.endEditing(true)

        // is reachable?
        if !ReachabilityUtils.isInternetReachable() {
            ReachabilityUtils.showAlertNoInternetConnection()
            return
        }


        // Is everything filled out?
        if verificationCodeField.nonNilTrimmedText().isEmpty {
            WPError.showAlertWithTitle(NSLocalizedString("Error", comment: "Title of an error message"),
                                       message: NSLocalizedString("Please fill out all the fields", comment: "A short prompt asking the user to properly fill out all login fields."),
                                       withSupportButton: false)

            return
        }

        configureLoading(true)

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

        configureSubmitButton(false)
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
}


extension Signin2FAViewController: LoginFacadeDelegate {

    func finishedLoginWithUsername(username: String!, authToken: String!, requiredMultifactorCode: Bool) {
        syncWPCom(username, authToken: authToken, requiredMultifactor: requiredMultifactorCode)
    }


    func displayLoginMessage(message: String!) {
        configureStatusMessage(message)
    }


    func displayRemoteError(error: NSError!) {
        configureSubmitButton(false)
        displayError(error)
    }

}
