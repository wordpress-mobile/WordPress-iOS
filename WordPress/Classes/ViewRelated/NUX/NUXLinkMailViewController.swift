import UIKit

/// Step two in the auth link flow. This VC prompts the user to open their email
/// app to look for the emailed authentication link.
///
class NUXLinkMailViewController: LoginViewController {
    @IBOutlet var label: UILabel?
    @IBOutlet var openMailButton: NUXSubmitButton?
    @IBOutlet var usePasswordButton: UIButton?
    var emailMagicLinkSource: EmailMagicLinkSource?
    override var sourceTag: WordPressSupportSourceTag {
        get {
            return .loginMagicLink
        }
    }


    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        let email = loginFields.username
        if !email.isValidEmail() {
            assert(email.isValidEmail(), "The value of loginFields.username was not a valid email address.")
        }

        emailMagicLinkSource = loginFields.meta.emailMagicLinkSource
        assert(emailMagicLinkSource != nil, "Must have an email link source.")

        localizeControls()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard let emailMagicLinkSource = emailMagicLinkSource else {
            return
        }

        switch emailMagicLinkSource {
        case .login:
            WordPressAuthenticator.post(event: .loginMagicLinkOpenEmailClientViewed)
        case .signup:
            WordPressAuthenticator.post(event: .signupMagicLinkOpenEmailClientViewed)

            let message = "Email was not actually sent. This is a work in progress. If you need to create an account, disable the socialSignup feature flag."
            let alertController = UIAlertController(title: nil,
                                                    message: message,
                                                    preferredStyle: .alert)
            alertController.addDefaultActionWithTitle("OK")
            self.present(alertController, animated: true, completion: nil)
        }
    }

    // MARK: - Configuration

    /// Assigns localized strings to various UIControl defined in the storyboard.
    ///
    @objc func localizeControls() {

        let openMailButtonTitle = NSLocalizedString("Open Mail", comment: "Title of a button. The text should be capitalized.  Clicking opens the mail app in the user's iOS device.")
        openMailButton?.setTitle(openMailButtonTitle, for: UIControlState())
        openMailButton?.setTitle(openMailButtonTitle, for: .highlighted)

        let usePasswordTitle = NSLocalizedString("Enter your password instead.", comment: "Title of a button on the magic link screen.")
        usePasswordButton?.setTitle(usePasswordTitle, for: UIControlState())
        usePasswordButton?.setTitle(usePasswordTitle, for: .highlighted)
        usePasswordButton?.titleLabel?.numberOfLines = 0

        guard let emailMagicLinkSource = emailMagicLinkSource else {
            return
        }

        usePasswordButton?.isHidden = emailMagicLinkSource == .signup

        label?.text = {
            switch emailMagicLinkSource {
            case .login:
                return NSLocalizedString("Your magic link is on its way! Check your email on this device, and tap the link in the email you receive from WordPress.com", comment: "Instructional text on how to open the email containing a magic link.")
            case .signup:
                return NSLocalizedString("We sent an email with a link, open it to proceed with your new WordPress.com account.", comment: "Instructional text on how to open the email containing a magic link.")
            }
        }()
    }

    // MARK: - Actions

    @IBAction func handleOpenMailTapped(_ sender: UIButton) {
        let url = URL(string: "message://")!
        UIApplication.shared.open(url)
    }

    @IBAction func handleUsePasswordTapped(_ sender: UIButton) {
        WordPressAuthenticator.post(event: .loginMagicLinkExited)
    }
}
