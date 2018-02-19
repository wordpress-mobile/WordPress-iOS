import UIKit
import Lottie

class LoginPrologueViewController: UIViewController, UIViewControllerTransitioningDelegate {

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
        configureButtonVC()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        WordPressAuthenticator.post(event: .loginPrologueViewed)
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
        }
        else if let vc = segue.destination as? LoginPrologueSignupMethodViewController {
            vc.transitioningDelegate = self
            vc.emailTapped = { [weak self] in
                self?.performSegue(withIdentifier: NUXViewController.SegueIdentifier.showSigninV2.rawValue, sender: self)
            }
            vc.modalPresentationStyle = .custom
        }
    }

    private func configureButtonVC() {
        guard let buttonViewController = buttonViewController else {
            return
        }

        let loginTitle = NSLocalizedString("Log In", comment: "Button title.  Tapping takes the user to the login form.")
        let createTitle = NSLocalizedString("Signup to WordPress.com", comment: "Button title. Tapping begins the process of creating a WordPress.com account.")
        buttonViewController.setupTopButton(title: loginTitle, isPrimary: true) { [weak self] in
            self?.performSegue(withIdentifier: NUXViewController.SegueIdentifier.showEmailLogin.rawValue, sender: self)
        }
        buttonViewController.setupButtomButton(title: createTitle, isPrimary: false) { [weak self] in
            self?.signupTapped()
        }
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
            performSegue(withIdentifier: NUXViewController.SegueIdentifier.showSignupMethod.rawValue, sender: self)
        } else {
            performSegue(withIdentifier: "showSigninV1", sender: self)
        }
    }

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        if presented is LoginPrologueSignupMethodViewController {
            return FancyAlertPresentationController(presentedViewController: presented, presenting: presenting)
        }

        return nil
    }
}
