import UIKit

class LoginLinkAuthViewController: SigninLinkAuthViewController {
    override func dismiss() {
        self.performSegue(withIdentifier: .showEpilogue, sender: self)
    }
}
