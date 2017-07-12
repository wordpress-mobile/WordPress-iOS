import UIKit
import Lottie

class LoginPrologueViewController: UIViewController {

    @IBOutlet var loginButton: UIButton!
    @IBOutlet var signupButton: UIButton!

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        localizeControls()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.isPad() ? .all : .portrait
    }

    // MARK: - Setup and Config

    func localizeControls() {
        loginButton.setTitle(NSLocalizedString("Log In", comment: "Button title.  Tapping takes the user to the login form."),
                             for: .normal)

        signupButton.setTitle(NSLocalizedString("Create a WordPress site", comment: "Button title. Tapping takes the user to a form where they can create a new WordPress site."),
                              for: .normal)

    }
}
