import UIKit

class LoginLinkAuthViewController: SigninLinkAuthViewController {
    // let the storyboard's style stay
    override func setupStyles() {}

    override func dismiss() {
        self.performSegue(withIdentifier: .showEpilogue, sender: self)
    }
}
