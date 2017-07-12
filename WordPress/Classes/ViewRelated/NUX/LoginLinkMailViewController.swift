import UIKit

/// Step two in the auth link flow. This VC prompts the user to open their email
/// app to look for the emailed authentication link.
///
class LoginLinkMailViewController: LoginViewController {
    @IBOutlet var label: UILabel?
    @IBOutlet var openMailButton: NUXSubmitButton?
    @IBOutlet var usePasswordButton: UIButton?

    override var sourceTag: SupportSourceTag {
        get {
            return .wpComLogin
        }
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
        let instructions = NSLocalizedString("Your magic link is on its way! Check your email on this device, and tap the link in the email you receive from WordPress.com", comment: "Instructional text on how to open the email containing a magic link.")
        label?.text = instructions

        let openMailButtonTitle = NSLocalizedString("Open Mail", comment: "Title of a button. The text should be capitalized.  Clicking opens the mail app in the user's iOS device.")
        openMailButton?.setTitle(openMailButtonTitle, for: UIControlState())
        openMailButton?.setTitle(openMailButtonTitle, for: .highlighted)

        let usePasswordTitle = NSLocalizedString("Enter your password instead.", comment: "Title of a button on the magic link screen.")
        usePasswordButton?.setTitle(usePasswordTitle, for: UIControlState())
        usePasswordButton?.setTitle(usePasswordTitle, for: .highlighted)
        usePasswordButton?.titleLabel?.numberOfLines = 0
    }

    // let the storyboard's style stay
    override func setupStyles() {}


    // MARK: - Actions

    @IBAction func handleOpenMailTapped(_ sender: UIButton) {
        let url = URL(string: "message://")!
        UIApplication.shared.open(url)
    }

    @IBAction func handleUsePasswordTapped(_ sender: UIButton) {
        WPAppAnalytics.track(.loginMagicLinkExited)
    }
}
