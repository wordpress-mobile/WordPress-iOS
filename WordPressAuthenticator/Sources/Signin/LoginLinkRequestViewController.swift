import UIKit
import WordPressShared
import WordPressUI
import GravatarUI

/// Step one in the auth link flow. This VC displays a form to request a "magic"
/// authentication link be emailed to the user.  Allows the user to signin via
/// email instead of their password.
///
class LoginLinkRequestViewController: LoginViewController {
    @IBOutlet var gravatarView: UIImageView?
    @IBOutlet var label: UILabel?
    @IBOutlet var sendLinkButton: NUXButton?
    @IBOutlet var usePasswordButton: UIButton?
    override var sourceTag: WordPressSupportSourceTag {
        get {
            return .loginMagicLink
        }
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        localizeControls()
        configureUsePasswordButton()

        let email = loginFields.username
        if !email.isValidEmail() {
            assert(email.isValidEmail(), "The value of loginFields.username was not a valid email address.")
        }
        NotificationCenter.default.addObserver(self, selector: #selector(refreshAvatar), name: .GravatarQEAvatarUpdateNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let email = loginFields.username
        if email.isValidEmail() {
            Task {
                try await downloadAvatar()
            }
        } else {
            gravatarView?.isHidden = true
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        WordPressAuthenticator.track(.loginMagicLinkRequestFormViewed)
    }

    private func downloadAvatar(forceRefresh: Bool = false) async throws {
        let email = loginFields.username
        try await gravatarView?.setGravatarImage(with: email, rating: .x, forceRefresh: forceRefresh)
    }

    @objc private func refreshAvatar(_ notification: Foundation.Notification) {
        guard notification.userInfoHasEmail(loginFields.username) else { return }
        Task {
            try await downloadAvatar(forceRefresh: true)
        }
    }

    // MARK: - Configuration

    /// Assigns localized strings to various UIControl defined in the storyboard.
    ///
    @objc func localizeControls() {
        let format = NSLocalizedString("We'll email you a magic link that'll log you in instantly, no password needed. Hunt and peck no more!", comment: "Instructional text for the magic link login flow.")
        label?.text = NSString(format: format as NSString, loginFields.username) as String
        label?.font = WPStyleGuide.mediumWeightFont(forStyle: .subheadline)
        label?.textColor = WordPressAuthenticator.shared.style.instructionColor
        label?.adjustsFontForContentSizeCategory = true

        let sendLinkButtonTitle = NSLocalizedString("Send Link", comment: "Title of a button. The text should be uppercase.  Clicking requests a hyperlink be emailed ot the user.")
        sendLinkButton?.setTitle(sendLinkButtonTitle, for: .normal)
        sendLinkButton?.setTitle(sendLinkButtonTitle, for: .highlighted)
        sendLinkButton?.accessibilityIdentifier = "Send Link Button"

        let usePasswordTitle = NSLocalizedString("Enter your password instead.", comment: "Title of a button. ")
        usePasswordButton?.setTitle(usePasswordTitle, for: .normal)
        usePasswordButton?.setTitle(usePasswordTitle, for: .highlighted)
        usePasswordButton?.titleLabel?.numberOfLines = 0
        usePasswordButton?.titleLabel?.textAlignment = .center
        usePasswordButton?.accessibilityIdentifier = "Use Password"
    }

    @objc func configureLoading(_ animating: Bool) {
        sendLinkButton?.showActivityIndicator(animating)

        sendLinkButton?.isEnabled = !animating
    }

    private func configureUsePasswordButton() {
        guard let usePasswordButton else {
            return
        }
        WPStyleGuide.configureTextButton(usePasswordButton)
    }

    // MARK: - Instance Methods

    /// Makes the call to request a magic authentication link be emailed to the user.
    ///
    @objc func requestAuthenticationLink() {

        loginFields.meta.emailMagicLinkSource = .login

        let email = loginFields.username
        guard email.isValidEmail() else {
            // This is a bit of paranoia as in practice it should never happen.
            // However, let's make sure we give the user some useful feedback just in case.
            WPAuthenticatorLogError("Attempted to request authentication link, but the email address did not appear valid.")
            let alert = UIAlertController(title: NSLocalizedString("Can Not Request Link", comment: "Title of an alert letting the user know"), message: NSLocalizedString("A valid email address is needed to mail an authentication link. Please return to the previous screen and provide a valid email address.", comment: "An error message."), preferredStyle: .alert)
            alert.addActionWithTitle(NSLocalizedString("Need help?", comment: "Takes the user to get help"), style: .cancel, handler: { _ in WordPressAuthenticator.shared.delegate?.presentSupportRequest(from: self, sourceTag: .loginEmail) })
            alert.addActionWithTitle(NSLocalizedString("OK", comment: "Dismisses the alert"), style: .default, handler: nil)
            self.present(alert, animated: true, completion: nil)
            return
        }

        configureLoading(true)
        let service = WordPressComAccountService()
        service.requestAuthenticationLink(for: email,
                                          jetpackLogin: loginFields.meta.jetpackLogin,
                                          success: { [weak self] in
                                            self?.didRequestAuthenticationLink()
                                            self?.configureLoading(false)

            }, failure: { [weak self] (error: Error) in
                WordPressAuthenticator.track(.loginMagicLinkFailed)
                WordPressAuthenticator.track(.loginFailed, error: error)
                guard let strongSelf = self else {
                    return
                }
                strongSelf.displayError(error, sourceTag: strongSelf.sourceTag)
                strongSelf.configureLoading(false)
        })
    }

    // MARK: - Dynamic type
    override func didChangePreferredContentSize() {
        label?.font = WPStyleGuide.fontForTextStyle(.headline)
    }

    // MARK: - Actions

    @IBAction func handleUsePasswordTapped(_ sender: UIButton) {
        guard let vc = LoginWPComViewController.instantiate(from: .login) else {
            WPAuthenticatorLogError("Failed to navigate from LoginLinkRequestViewController to LoginWPComViewController")
            return
        }

        vc.loginFields = loginFields
        vc.dismissBlock = dismissBlock
        vc.errorToPresent = errorToPresent

        navigationController?.pushViewController(vc, animated: true)
        WordPressAuthenticator.track(.loginMagicLinkExited)
    }

    @IBAction func handleSendLinkTapped(_ sender: UIButton) {
        requestAuthenticationLink()
    }

    @objc func didRequestAuthenticationLink() {
        WordPressAuthenticator.track(.loginMagicLinkRequested)

        guard let vc = NUXLinkMailViewController.instantiate(from: .emailMagicLink) else {
            WPAuthenticatorLogError("Failed to navigate to NUXLinkMailViewController")
            return
        }

        vc.loginFields = self.loginFields
        vc.loginFields.restrictToWPCom = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension LoginLinkRequestViewController {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            didChangePreferredContentSize()
        }
    }
}
