import UIKit
import MessageUI
import WordPressShared


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
            if let emailMagicLinkSource = emailMagicLinkSource,
                emailMagicLinkSource == .signup {
                return .wpComSignupMagicLink
            }
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
                return NSLocalizedString("We sent you a magic signup link! Check your email on this device, and tap the link in the email to finish signing up.", comment: "Instructional text on how to open the email containing a magic link.")
            }
        }()
    }

    // MARK: - Dynamic type
    override func didChangePreferredContentSize() {
        label?.font = WPStyleGuide.fontForTextStyle(.headline)
    }

    // MARK: - Actions

    @IBAction func handleOpenMailTapped(_ sender: UIButton) {
        defer {
            if let emailMagicLinkSource = emailMagicLinkSource {
                switch emailMagicLinkSource {
                case .login:
                    WordPressAuthenticator.track(.loginMagicLinkOpenEmailClientViewed)
                case .signup:
                    WordPressAuthenticator.track(.signupMagicLinkOpenEmailClientViewed)
                }
            }
        }
        if MFMailComposeViewController.canSendMail() {
            let url = URL(string: "message://")!
            UIApplication.shared.open(url)
        } else if let googleMailURL = URL(string: "googlegmail://"),
            UIApplication.shared.canOpenURL(googleMailURL) {
            UIApplication.shared.open(googleMailURL)
        } else {
            showAlertToCheckEmail()
        }
    }

    func showAlertToCheckEmail() {
        let title = NSLocalizedString("Please check your email", comment: "Alert title for check your email during logIn/signUp.")
        let message = NSLocalizedString("Please open your email app and look for an email from WordPress.com.", comment: "Message to ask the user to check their email and look for a WordPress.com email.")

        let alertController =  UIAlertController(title: title,
                                                 message: message,
                                                 preferredStyle: .alert)
        alertController.addCancelActionWithTitle(NSLocalizedString("OK",
                                                                   comment: "Button title. An acknowledgement of the message displayed in a prompt."))
        self.present(alertController, animated: true, completion: nil)
    }


    @IBAction func handleUsePasswordTapped(_ sender: UIButton) {
        WordPressAuthenticator.track(.loginMagicLinkExited)
    }
}

extension NUXLinkMailViewController {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            didChangePreferredContentSize()
        }
    }
}
