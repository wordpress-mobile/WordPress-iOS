import UIKit

class LoginWPComViewController: SigninWPComViewController {
    // let the storyboard's style stay
    override func setupStyles() {}

    override func dismiss() {
        self.performSegue(withIdentifier: .showEpilogue, sender: self)
    }

    override func needsMultifactorCode() {
        configureStatusLabel("")
        configureViewLoading(false)

        WPAppAnalytics.track(.twoFactorCodeRequested)
        self.performSegue(withIdentifier: .show2FA, sender: self)
    }
}
