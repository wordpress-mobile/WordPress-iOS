import UIKit

/// Step one in the auth link flow. This VC displays a form to request a "magic"
/// authentication link be emailed to the user.  Allows the user to signin via
/// email instead of their password.
///
class SigninLinkRequestViewController: NUXAbstractViewController {

    @IBOutlet var label: UILabel!
    @IBOutlet var sendLinkButton: NUXSubmitButton!
    @IBOutlet var usePasswordButton: UIButton!

    override var sourceTag: SupportSourceTag {
        get {
            return .wpComLogin
        }
    }

    /// A convenience method for obtaining an instance of the controller from a storyboard.
    ///
    /// - Parameter loginFields: A LoginFields instance containing any prefilled credentials.
    ///
    class func controller(_ loginFields: LoginFields) -> SigninLinkRequestViewController {
        let storyboard = UIStoryboard(name: "Signin", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "SigninLinkRequestViewController") as! SigninLinkRequestViewController
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


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        assert(SigninHelpers.controllerWasPresentedFromRootViewController(self),
               "Only present parts of the magic link signin flow from the application's root vc.")
    }


    // MARK: - Configuration


    /// Assigns localized strings to various UIControl defined in the storyboard.
    ///
    func localizeControls() {
        let format = NSLocalizedString("Get a link sent to %@ to log in instantly.", comment: "Short instructional text. The %@ is a placeholder for the user's email address.")
        label.text = NSString(format: format as NSString, loginFields.username) as String

        let sendLinkButtonTitle = NSLocalizedString("Send Link", comment: "Title of a button. The text should be uppercase.  Clicking requests a hyperlink be emailed ot the user.").localizedUppercase
        sendLinkButton.setTitle(sendLinkButtonTitle, for: UIControlState())
        sendLinkButton.setTitle(sendLinkButtonTitle, for: .highlighted)

        let usePasswordTitle = NSLocalizedString("Enter your password instead", comment: "Title of a button. ")
        usePasswordButton.setTitle(usePasswordTitle, for: UIControlState())
        usePasswordButton.setTitle(usePasswordTitle, for: .highlighted)
    }


    func configureLoading(_ animating: Bool) {
        sendLinkButton.showActivityIndicator(animating)

        sendLinkButton.isEnabled = !animating
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
            WPError.showAlert(withTitle: NSLocalizedString("Can Not Request Link", comment: "Title of an alert letting the user know"),
                                       message: NSLocalizedString("A valid email address is needed to mail an authentication link. Please return to the previous screen and provide a valid email address.", comment: "An error message."))
            return
        }

        configureLoading(true)
        let service = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.requestAuthenticationLink(email,
            success: { [weak self] in
                self?.didRequestAuthenticationLink()
                self?.configureLoading(false)

            }, failure: { [weak self] (error: Error) in
                WPAppAnalytics.track(.loginMagicLinkFailed)
                guard let strongSelf = self else {
                    return
                }
                strongSelf.displayError(error as NSError, sourceTag: strongSelf.sourceTag)
                strongSelf.configureLoading(false)
            })
    }


    /// Displays the next step in the magic links sign in flow.
    ///
    func didRequestAuthenticationLink() {
        WPAppAnalytics.track(.loginMagicLinkRequested)
        SigninHelpers.saveEmailAddressForTokenAuth(loginFields.username)
        let controller = SigninLinkMailViewController.controller(loginFields)
        controller.dismissBlock = dismissBlock
        controller.restrictToWPCom = restrictToWPCom
        navigationController?.pushViewController(controller, animated: true)
    }


    // MARK: - Actions


    @IBAction func handleSendLinkTapped(_ sender: UIButton) {
        requestAuthenticationLink()
    }


    @IBAction func handleUsePasswordTapped(_ sender: UIButton) {
        WPAppAnalytics.track(.loginMagicLinkExited)
        let controller = SigninWPComViewController.controller(loginFields)
        controller.dismissBlock = dismissBlock
        controller.restrictToWPCom = restrictToWPCom
        navigationController?.pushViewController(controller, animated: true)
    }

}
