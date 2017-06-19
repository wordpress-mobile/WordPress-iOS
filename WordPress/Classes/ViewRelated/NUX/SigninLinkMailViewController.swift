import UIKit

/// Step two in the auth link flow. This VC prompts the user to open their email
/// app to look for the emailed authentication link.
///
class SigninLinkMailViewController: NUXAbstractViewController {

    @IBOutlet var label: UILabel!
    @IBOutlet var openMailButton: NUXSubmitButton!
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
    class func controller(_ loginFields: LoginFields) -> SigninLinkMailViewController {
        let storyboard = UIStoryboard(name: "Signin", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "SigninLinkMailViewController") as! SigninLinkMailViewController
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


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        assert(SigninHelpers.controllerWasPresentedFromRootViewController(self),
               "Only present parts of the magic link signin flow from the application's root vc.")
    }


    // MARK: - Configuration


    /// Assigns localized strings to various UIControl defined in the storyboard.
    ///
    func localizeControls() {
        let format = NSLocalizedString("We've sent your link to %@.", comment: "Short instructional text. The %@ is a placeholder for the user's email address.")
        label.text = NSString(format: format as NSString, loginFields.username) as String

        let openMailButtonTitle = NSLocalizedString("Open Mail", comment: "Title of a button. The text should be uppercase.  Clicking opens the mail app in the user's iOS device.").localizedUppercase
        openMailButton.setTitle(openMailButtonTitle, for: UIControlState())
        openMailButton.setTitle(openMailButtonTitle, for: .highlighted)

        let usePasswordTitle = NSLocalizedString("Enter your password instead", comment: "Title of a button. ")
        usePasswordButton.setTitle(usePasswordTitle, for: UIControlState())
        usePasswordButton.setTitle(usePasswordTitle, for: .highlighted)
    }


    // MARK: - Actions


    @IBAction func handleOpenMailTapped(_ sender: UIButton) {
        let url = URL(string: "message://")!
        UIApplication.shared.open(url)
    }


    @IBAction func handleUsePasswordTapped(_ sender: UIButton) {
        WPAppAnalytics.track(.loginMagicLinkExited)
        let controller = SigninWPComViewController.controller(loginFields)
        controller.dismissBlock = dismissBlock
        controller.restrictToWPCom = restrictToWPCom
        navigationController?.pushViewController(controller, animated: true)
    }
}
