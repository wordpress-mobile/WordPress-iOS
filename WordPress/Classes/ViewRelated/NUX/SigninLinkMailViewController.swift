import UIKit

/// Step two in the auth link flow. This VC prompts the user to open their email
/// app to look for the emailed authentication link.
///
class SigninLinkMailViewController : NUXAbstractViewController
{

    @IBOutlet var label: UILabel!
    @IBOutlet var openMailButton: NUXSubmitButton!
    @IBOutlet var usePasswordButton: UIButton!
    var restrictSigninToWPCom = false

    /// A convenience method for obtaining an instance of the controller from a storyboard.
    ///
    /// - Parameter loginFields: A LoginFields instance containing any prefilled credentials.
    ///
    class func controller(loginFields: LoginFields) -> SigninLinkMailViewController {
        let storyboard = UIStoryboard(name: "Signin", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("SigninLinkMailViewController") as! SigninLinkMailViewController
        controller.loginFields = loginFields
        return controller
    }


    // MARK: - Lifecycle Methods


    override func viewDidLoad() {
        super.viewDidLoad()

        let email = loginFields.username
        if !email.isValidEmail() {
            assert(email.isValidEmail(), "The value of loginFields.username was not a valid email address.")
        }

        localizeControls()
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
        let format = NSLocalizedString("We've sent your link to %@.", comment: "Short instructional text. The %@ is a placeholder for the user's email address.")
        label.text = NSString(format: format, loginFields.username) as String

        let openMailButtonTitle = NSLocalizedString("Open Mail", comment: "Title of a button. The text should be uppercase.  Clicking opens the mail app in the user's iOS device.").localizedUppercaseString
        openMailButton.setTitle(openMailButtonTitle, forState: .Normal)
        openMailButton.setTitle(openMailButtonTitle, forState: .Highlighted)

        let usePasswordTitle = NSLocalizedString("Enter your password instead", comment: "Title of a button. ")
        usePasswordButton.setTitle(usePasswordTitle, forState: .Normal)
        usePasswordButton.setTitle(usePasswordTitle, forState: .Highlighted)
    }


    // MARK: - Actions


    @IBAction func handleOpenMailTapped(sender: UIButton) {
        let url = NSURL(string: "message://")!
        UIApplication.sharedApplication().openURL(url)
    }


    @IBAction func handleUsePasswordTapped(sender: UIButton) {
        WPAppAnalytics.track(.LoginMagicLinkExited)
        let controller = SigninWPComViewController.controller(loginFields)
        controller.dismissBlock = dismissBlock
        controller.restrictSigninToWPCom = restrictSigninToWPCom
        navigationController?.pushViewController(controller, animated: true)
    }
}
