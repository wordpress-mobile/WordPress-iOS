import UIKit

class Login2FAViewController: Signin2FAViewController {
    override func dismiss() {
        self.performSegue(withIdentifier: "showEpilogue", sender: self)
    }
}
