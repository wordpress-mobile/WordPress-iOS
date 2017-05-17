import UIKit

class LoginEmailViewController: SigninEmailViewController {
    // let the storyboard's style stay
    override func setupStyles() {}

    override func requestLink() {
        performSegue(withIdentifier: .startMagicLinkFlow, sender: self)
    }

    override func signinWithUsernamePassword(_ immediateSignin: Bool = false) {
        performSegue(withIdentifier: .showWPComLogin, sender: self)
    }

    override func signinToSelfHostedSite() {
        performSegue(withIdentifier: .showSelfHostedLogin, sender: self)
    }
}
