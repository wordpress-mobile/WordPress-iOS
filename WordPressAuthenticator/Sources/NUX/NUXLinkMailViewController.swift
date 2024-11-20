import UIKit
import WordPressShared

/// Step two in the auth link flow. This VC prompts the user to open their email
/// app to look for the emailed authentication link.
///
class NUXLinkMailViewController: LoginViewController {
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet var label: UILabel?
    @IBOutlet var openMailButton: NUXButton?
    @IBOutlet var usePasswordButton: UIButton?
    var emailMagicLinkSource: EmailMagicLinkSource?
    override var sourceTag: WordPressSupportSourceTag {
        get {
            if let emailMagicLinkSource,
                emailMagicLinkSource == .signup {
                return .wpComSignupMagicLink
            }
            return .loginMagicLink
        }
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.image = WordPressAuthenticator.shared.displayImages.magicLink

        let email = loginFields.username
        if !email.isValidEmail() {
            assert(email.isValidEmail(), "The value of loginFields.username was not a valid email address.")
        }

        emailMagicLinkSource = loginFields.meta.emailMagicLinkSource
        assert(emailMagicLinkSource != nil, "Must have an email link source.")

        styleUsePasswordButton()
        localizeControls()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: - Configuration

    private func styleUsePasswordButton() {
        guard let usePasswordButton else {
            return
        }
        WPStyleGuide.configureTextButton(usePasswordButton)
    }

    /// Assigns localized strings to various UIControl defined in the storyboard.
    ///
    @objc func localizeControls() {

        let openMailButtonTitle = NSLocalizedString("Open Mail", comment: "Title of a button. The text should be capitalized.  Clicking opens the mail app in the user's iOS device.")
        openMailButton?.setTitle(openMailButtonTitle, for: .normal)
        openMailButton?.setTitle(openMailButtonTitle, for: .highlighted)
        openMailButton?.accessibilityIdentifier = "Open Mail Button"

        let usePasswordTitle = NSLocalizedString("Enter your password instead.", comment: "Title of a button on the magic link screen.")
        usePasswordButton?.setTitle(usePasswordTitle, for: .normal)
        usePasswordButton?.setTitle(usePasswordTitle, for: .highlighted)
        usePasswordButton?.titleLabel?.numberOfLines = 0
        usePasswordButton?.accessibilityIdentifier = "Use Password"

        guard let emailMagicLinkSource else {
            return
        }

        usePasswordButton?.isHidden = emailMagicLinkSource == .signup

        label?.text = NSLocalizedString("Check your email on this device, and tap the link in the email you received from WordPress.com.\n\nNot seeing the email? Check your Spam or Junk Mail folder.", comment: "Instructional text on how to open the email containing a magic link.")

        label?.textColor = WordPressAuthenticator.shared.style.instructionColor
    }

    // MARK: - Dynamic type
    override func didChangePreferredContentSize() {
        label?.font = WPStyleGuide.fontForTextStyle(.headline)
    }

    // MARK: - Actions

    @IBAction func handleOpenMailTapped(_ sender: UIButton) {
        defer {
            if let emailMagicLinkSource {
                switch emailMagicLinkSource {
                case .login:
                    WordPressAuthenticator.track(.loginMagicLinkOpenEmailClientViewed)
                case .signup:
                    WordPressAuthenticator.track(.signupMagicLinkOpenEmailClientViewed)
                }
            }
        }

        let linkMailPresenter = LinkMailPresenter(emailAddress: loginFields.username)
        let appSelector = AppSelector(sourceView: sender)
        linkMailPresenter.presentEmailClients(on: self, appSelector: appSelector)
    }

    @IBAction func handleUsePasswordTapped(_ sender: UIButton) {
        WordPressAuthenticator.track(.loginMagicLinkExited)
        guard let vc = LoginWPComViewController.instantiate(from: .login) else {
            WPAuthenticatorLogError("Failed to navigate to LoginWPComViewController from NUXLinkMailViewController")
            return
        }

        vc.loginFields = loginFields
        vc.dismissBlock = dismissBlock
        vc.errorToPresent = errorToPresent

        navigationController?.pushViewController(vc, animated: true)
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
