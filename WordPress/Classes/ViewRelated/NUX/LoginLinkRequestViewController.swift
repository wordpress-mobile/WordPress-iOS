import UIKit

class LoginLinkRequestViewController: SigninLinkRequestViewController, LoginViewController {
    // let the storyboard's style stay
    override func setupStyles() {}

    @IBAction override func handleUsePasswordTapped(_ sender: UIButton) {
        WPAppAnalytics.track(.loginMagicLinkExited)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBarIcon()
    }

    override func didRequestAuthenticationLink() {
        WPAppAnalytics.track(.loginMagicLinkRequested)
        SigninHelpers.saveEmailAddressForTokenAuth(loginFields.username)
        performSegue(withIdentifier: .showLinkMailView, sender: self)
    }
}
