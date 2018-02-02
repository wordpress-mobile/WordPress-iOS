import UIKit
import Lottie

class LoginPrologueViewController: UIViewController, NUXButtonViewControllerDelegate {

    private var buttonViewController: NUXButtonViewController?

    @IBOutlet var loginButton: UIButton!
    @IBOutlet var signupButton: UIButton!

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        localizeControls()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        WPAppAnalytics.track(.loginPrologueViewed)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.isPad() ? .all : .portrait
    }

    // MARK: - Segue

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let vc = segue.destination as? NUXButtonViewController {
            buttonViewController = vc
            buttonViewController?.delegate = self
            buttonViewController?.setButtonTitles(primary: NSLocalizedString("Create site", comment: "Button text for creating a new site in the Site Creation process."))
            buttonViewController?.setButtonTitles(primary: "One", secondary: "Two")
            //showButtonView(show: false, withAnimation: false)
        }
    }

    func primaryButtonPressed() {
        //
    }

    // MARK: - Setup and Config

    @objc func localizeControls() {
        loginButton.setTitle(NSLocalizedString("Log In", comment: "Button title.  Tapping takes the user to the login form."),
                             for: .normal)
        loginButton.accessibilityIdentifier = "Log In"

        signupButton.setTitle(NSLocalizedString("Create a WordPress site", comment: "Button title. Tapping takes the user to a form where they can create a new WordPress site."),
                              for: .normal)

    }

    // MARK: - Actions

    @IBAction func signupTapped() {
        if Feature.enabled(.socialSignup) {

            // TODO: replace with Signup Prologue implementation

            let storyboard = UIStoryboard(name: "Signup", bundle: nil)
            let emailVC = storyboard.instantiateViewController(withIdentifier: "emailEntry")
            let navController = SignupNavigationController(rootViewController: emailVC)
            present(navController, animated: true, completion: nil)


        } else {
            performSegue(withIdentifier: "showSigninV1", sender: self)
        }
    }
}
