import UIKit

/// Step one in the auth link flow. This VC displays a form to request a "magic"
/// authentication link be emailed to the user.  Allows the user to signin via
/// email instead of their password.
///
class SigninLinkRequestViewController : NUXAbstractViewController
{

    @IBOutlet var label: UILabel!
    @IBOutlet var sendLinkButton: NUXSubmitButton!
    @IBOutlet var usePasswordButton: UIButton!
    var restrictSigninToWPCom = false

    /// A convenience method for obtaining an instance of the controller from a storyboard.
    ///
    /// - Parameter loginFields: A LoginFields instance containing any prefilled credentials.
    ///
    class func controller(loginFields: LoginFields) -> SigninLinkRequestViewController {
        let storyboard = UIStoryboard(name: "Signin", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("SigninLinkRequestViewController") as! SigninLinkRequestViewController
        controller.loginFields = loginFields
        return controller
    }


    // MARK: - Lifecycle Methods


    override func viewDidLoad() {
        super.viewDidLoad()

        localizeControls()

        let email = loginFields.username
        if !email.isValidEmail() {
            assert(email.isValidEmail(), "The value of loginFields.username was not a valid email address.")
        }
    }


    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        assert(SigninHelpers.controllerWasPresentedFromRootViewController(self),
               "Only present parts of the magic link signin flow from the application's root vc.")
    }


    // MARK: - Configuration


    /// Assigns localized strings to various UIControl defined in the storyboard.
    ///
    func localizeControls() {
        let format = NSLocalizedString("Get a link sent to %@ to sign in instantly.", comment: "Short instructional text. The %@ is a placeholder for the user's email address.")
        label.text = NSString(format: format, loginFields.username) as String

        let sendLinkButtonTitle = NSLocalizedString("Send Link", comment: "Title of a button. The text should be uppercase.  Clicking requests a hyperlink be emailed ot the user.").localizedUppercaseString
        sendLinkButton.setTitle(sendLinkButtonTitle, forState: .Normal)
        sendLinkButton.setTitle(sendLinkButtonTitle, forState: .Highlighted)

        let usePasswordTitle = NSLocalizedString("Enter your password instead", comment: "Title of a button. ")
        usePasswordButton.setTitle(usePasswordTitle, forState: .Normal)
        usePasswordButton.setTitle(usePasswordTitle, forState: .Highlighted)
    }


    func configureLoading(animating: Bool) {
        sendLinkButton.showActivityIndicator(animating)

        sendLinkButton.enabled = !animating
    }


    // MARK: - Instance Methods


    /// Makes the call to request a magic authentication link be emailed to the user.
    ///
    func requestAuthenticationLink() {
        let email = loginFields.username
        guard email.isValidEmail() else {
            // This is a bit of paranioa as in practice it should never happen.
            // However, let's make sure we give the user some useful feedback just in case.
            DDLogSwift.logError("Attempted to request authentication link, but the email address did not appear valid.")
            WPError.showAlertWithTitle(NSLocalizedString("Can Not Request Link", comment: "Title of an alert letting the user know"),
                                       message: NSLocalizedString("A valid email address is needed to mail an authentication link. Please return to the previous screen and provide a valid email address.", comment: "An error message."))
            return
        }

        configureLoading(true)
        let service = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.requestAuthenticationLink(email,
            success: { [weak self] in
                self?.didRequestAuthenticationLink()
                self?.configureLoading(false)

            }, failure: { [weak self] (error: NSError!) in
                WPAppAnalytics.track(.LoginMagicLinkFailed)
                self?.displayError(error)
                self?.configureLoading(false)
            })
    }


    /// Displays the next step in the magic links sign in flow.
    ///
    func didRequestAuthenticationLink() {
        WPAppAnalytics.track(.LoginMagicLinkRequested)
        SigninHelpers.saveEmailAddressForTokenAuth(loginFields.username)
        let controller = SigninLinkMailViewController.controller(loginFields)
        controller.dismissBlock = dismissBlock
        controller.restrictSigninToWPCom = restrictSigninToWPCom
        navigationController?.pushViewController(controller, animated: true)
    }


    // MARK: - Actions


    @IBAction func handleSendLinkTapped(sender: UIButton) {
        requestAuthenticationLink()
    }


    @IBAction func handleUsePasswordTapped(sender: UIButton) {
        WPAppAnalytics.track(.LoginMagicLinkExited)
        let controller = SigninWPComViewController.controller(loginFields)
        controller.dismissBlock = dismissBlock
        controller.restrictSigninToWPCom = restrictSigninToWPCom
        navigationController?.pushViewController(controller, animated: true)
    }

}
