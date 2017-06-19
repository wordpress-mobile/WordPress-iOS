import UIKit

class LoginLinkAuthViewController: SigninLinkAuthViewController, LoginViewController {
    // let the storyboard's style stay
    override func setupStyles() {}

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBarIcon()
    }

    override func dismiss() {
        self.performSegue(withIdentifier: .showEpilogue, sender: self)
    }
}
