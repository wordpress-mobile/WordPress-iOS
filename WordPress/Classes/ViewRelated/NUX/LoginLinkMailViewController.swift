import UIKit

class LoginLinkMailViewController: SigninLinkMailViewController, LoginViewController {
    // let the storyboard's style stay
    override func setupStyles() {}

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBarIcon()
    }

    @IBAction override func handleUsePasswordTapped(_ sender: UIButton) {
        WPAppAnalytics.track(.loginMagicLinkExited)
    }

    override func localizeControls() {
        let instructions = NSLocalizedString("Your magic link is on its way! Check your email on this device, and tap the link in the email you receive from WordPress.com", comment: "Instructional text on how to open the email containing a magic link.")
        label.text = instructions

        let openMailButtonTitle = NSLocalizedString("Open Mail", comment: "Title of a button. The text should be capitalized.  Clicking opens the mail app in the user's iOS device.")
        openMailButton.setTitle(openMailButtonTitle, for: UIControlState())
        openMailButton.setTitle(openMailButtonTitle, for: .highlighted)

        let usePasswordTitle = NSLocalizedString("Enter your password instead.", comment: "Title of a button on the magic link screen.")
        usePasswordButton.setTitle(usePasswordTitle, for: UIControlState())
        usePasswordButton.setTitle(usePasswordTitle, for: .highlighted)
    }
}
