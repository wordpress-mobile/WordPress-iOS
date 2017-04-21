import UIKit

class LoginLinkRequestViewController: SigninLinkRequestViewController {
    @IBAction override func handleUsePasswordTapped(_ sender: UIButton) {
        WPAppAnalytics.track(.loginMagicLinkExited)
    }

    override func didRequestAuthenticationLink() {
        WPAppAnalytics.track(.loginMagicLinkRequested)
        SigninHelpers.saveEmailAddressForTokenAuth(loginFields.username)
        performSegue(withIdentifier: "showLinkMailView", sender: self)
    }
}
