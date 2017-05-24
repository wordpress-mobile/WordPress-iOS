import UIKit

class Login2FAViewController: Signin2FAViewController, LoginViewController {
    // let the storyboard's style stay
    override func setupStyles() {}

    override func dismiss() {
        self.performSegue(withIdentifier: .showEpilogue, sender: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBarIcon()
    }
}
