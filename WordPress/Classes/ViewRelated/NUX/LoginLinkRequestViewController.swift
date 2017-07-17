import UIKit

class LoginLinkRequestViewController: SigninLinkRequestViewController, LoginViewController {
    @IBOutlet var gravatarView: UIImageView?

    // let the storyboard's style stay
    override func setupStyles() {}

    @IBAction override func handleUsePasswordTapped(_ sender: UIButton) {
        WPAppAnalytics.track(.loginMagicLinkExited)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBarIcon()
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

    /// Assigns localized strings to various UIControl defined in the storyboard.
    ///
    override func localizeControls() {
        let format = NSLocalizedString("We'll email you a magic link that'll log you in instantly, no password needed. Hunt and peck no more!", comment: "Instructional text for the magic link login flow.")
        label.text = NSString(format: format as NSString, loginFields.username) as String

        let sendLinkButtonTitle = NSLocalizedString("Send Link", comment: "Title of a button. The text should be uppercase.  Clicking requests a hyperlink be emailed ot the user.")
        sendLinkButton.setTitle(sendLinkButtonTitle, for: UIControlState())
        sendLinkButton.setTitle(sendLinkButtonTitle, for: .highlighted)

        let usePasswordTitle = NSLocalizedString("Enter your password instead.", comment: "Title of a button. ")
        usePasswordButton.setTitle(usePasswordTitle, for: UIControlState())
        usePasswordButton.setTitle(usePasswordTitle, for: .highlighted)
    }

    override func didRequestAuthenticationLink() {
        WPAppAnalytics.track(.loginMagicLinkRequested)
        SigninHelpers.saveEmailAddressForTokenAuth(loginFields.username)
        performSegue(withIdentifier: .showLinkMailView, sender: self)
    }
}
