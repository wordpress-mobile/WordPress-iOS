import UIKit
import Lottie

class LoginPrologueViewController: LoginViewController {

    private var buttonViewController: NUXButtonViewController?
    var showCancel = false

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - Lifecycle Methods

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureButtonVC()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        WordPressAuthenticator.track(.loginPrologueViewed)
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
            vc.googleTapped = { [weak self] in
                self?.performSegue(withIdentifier: NUXViewController.SegueIdentifier.showGoogle.rawValue, sender: self)
            }
            vc.modalPresentationStyle = .custom
        }
    }

    private func configureButtonVC() {
        guard let buttonViewController = buttonViewController else {
            return
        }

        let loginTitle = NSLocalizedString("Log In", comment: "Button title.  Tapping takes the user to the login form.")
        let createTitle = NSLocalizedString("Sign up for WordPress.com", comment: "Button title. Tapping begins the process of creating a WordPress.com account.")
        buttonViewController.setupTopButton(title: loginTitle, isPrimary: true) { [weak self] in
            self?.loginTapped()
        }
        buttonViewController.setupButtomButton(title: createTitle, isPrimary: false) { [weak self] in
            self?.signupTapped()
        }
        if showCancel {
            let cancelTitle = NSLocalizedString("Cancel", comment: "Button title. Tapping it cancels the login flow.")
            buttonViewController.setupTertiaryButton(title: cancelTitle, isPrimary: false) { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }
        }
        buttonViewController.backgroundColor = WPStyleGuide.lightGrey()
    }

    // MARK: - Actions

    private func loginTapped() {
        performSegue(withIdentifier: NUXViewController.SegueIdentifier.showEmailLogin.rawValue, sender: self)
    }

    private func signupTapped() {
        WordPressAuthenticator.track(.signupButtonTapped)
        performSegue(withIdentifier: NUXViewController.SegueIdentifier.showSignupMethod.rawValue, sender: self)
    }
}
