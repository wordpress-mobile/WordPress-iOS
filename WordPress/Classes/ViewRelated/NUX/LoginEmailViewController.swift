import UIKit

protocol LoginViewController {
    func setupNavBarIcon()
}

extension LoginViewController where Self: NUXAbstractViewController {
    func setupNavBarIcon() {
        let image = UIImage(named: "social-wordpress")
        let imageView = UIImageView(image: image?.imageWithTintColor(UIColor.white))
        navigationItem.titleView = imageView
    }
}

class LoginEmailViewController: SigninEmailViewController, LoginViewController {
    // let the storyboard's style stay
    override func setupStyles() {}

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBarIcon()
    }

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
