import UIKit

class LoginLinkMailViewController: SigninLinkMailViewController {
    // let the storyboard's style stay
    override func setupStyles() {}

    @IBAction override func handleUsePasswordTapped(_ sender: UIButton) {
        WPAppAnalytics.track(.loginMagicLinkExited)
    }
}
