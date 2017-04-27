import UIKit

class LoginSelfHostedViewController: SigninSelfHostedViewController {
    override func needsMultifactorCode() {
        self.performSegue(withIdentifier: .show2FA, sender: self)
    }

    override func dismiss() {
        self.performSegue(withIdentifier: .showEpilogue, sender: self)
    }
}
