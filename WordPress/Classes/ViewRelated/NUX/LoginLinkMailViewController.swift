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
}
