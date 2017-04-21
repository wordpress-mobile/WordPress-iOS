import UIKit

class LoginLinkMailViewController: SigninLinkMailViewController {
    @IBAction override func handleUsePasswordTapped(_ sender: UIButton) {
        WPAppAnalytics.track(.loginMagicLinkExited)
    }
}
