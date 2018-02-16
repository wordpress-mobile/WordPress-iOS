import UIKit
import CocoaLumberjack

/// Step one in the auth link flow. This VC displays a form to request a "magic"
/// authentication link be emailed to the user.  Allows the user to signin via
/// email instead of their password.
///
class LoginLinkRequestViewController: LoginViewController {
    @IBOutlet var gravatarView: UIImageView?
    @IBOutlet var label: UILabel?
    @IBOutlet var sendLinkButton: NUXSubmitButton?
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

        let email = loginFields.username
        if !email.isValidEmail() {
            assert(email.isValidEmail(), "The value of loginFields.username was not a valid email address.")
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let email = loginFields.username
        if email.isValidEmail() {
            gravatarView?.downloadGravatarWithEmail(email, rating: .x)
        } else {
            gravatarView?.isHidden = true
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        WordPressAuthenticator.post(event: .loginMagicLinkRequestFormViewed)
    }

    // MARK: - Configuration

    /// Assigns localized strings to various UIControl defined in the storyboard.
    ///
    @objc func localizeControls() {
        let format = NSLocalizedString("We'll email you a magic link that'll log you in instantly, no password needed. Hunt and peck no more!", comment: "Instructional text for the magic link login flow.")
        label?.text = NSString(format: format as NSString, loginFields.username) as String

        let sendLinkButtonTitle = NSLocalizedString("Send Link", comment: "Title of a button. The text should be uppercase.  Clicking requests a hyperlink be emailed ot the user.")
        sendLinkButton?.setTitle(sendLinkButtonTitle, for: UIControlState())
        sendLinkButton?.setTitle(sendLinkButtonTitle, for: .highlighted)

        let usePasswordTitle = NSLocalizedString("Enter your password instead.", comment: "Title of a button. ")
        usePasswordButton?.setTitle(usePasswordTitle, for: UIControlState())
        usePasswordButton?.setTitle(usePasswordTitle, for: .highlighted)
        usePasswordButton?.titleLabel?.numberOfLines = 0
        usePasswordButton?.accessibilityIdentifier = "Use Password"
    }

    @objc func configureLoading(_ animating: Bool) {
        sendLinkButton?.showActivityIndicator(animating)

        sendLinkButton?.isEnabled = !animating
    }


    // MARK: - Instance Methods

    /// Makes the call to request a magic authentication link be emailed to the user.
    ///
    @objc func requestAuthenticationLink() {

        loginFields.meta.emailMagicLinkSource = .login

        let email = loginFields.username
        guard email.isValidEmail() else {
            // This is a bit of paranioa as in practice it should never happen.
            // However, let's make sure we give the user some useful feedback just in case.
            DDLogError("Attempted to request authentication link, but the email address did not appear valid.")
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
                WordPressAuthenticator.post(event: .loginMagicLinkFailed)
                WordPressAuthenticator.post(event: .loginFailed(error: error))
                guard let strongSelf = self else {
                    return
                }
                strongSelf.displayError(error as NSError, sourceTag: strongSelf.sourceTag)
                strongSelf.configureLoading(false)
        })
    }

    // MARK: - Actions

    @IBAction func handleSendLinkTapped(_ sender: UIButton) {
        requestAuthenticationLink()
    }

    @objc func didRequestAuthenticationLink() {
        WordPressAuthenticator.post(event: .loginMagicLinkRequested)
        WordPressAuthenticator.storeLoginInfoForTokenAuth(loginFields)
        performSegue(withIdentifier: .showLinkMailView, sender: self)
    }

    @IBAction func handleUsePasswordTapped(_ sender: UIButton) {
        WordPressAuthenticator.post(event: .loginMagicLinkExited)
    }
}
