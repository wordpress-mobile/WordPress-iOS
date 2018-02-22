class LoginPrologueSignupMethodViewController: UIViewController {
    /// Buttons at bottom of screen
    private var buttonViewController: NUXButtonViewController?

    /// Gesture recognizer for taps on the dialog if no buttons are present
    fileprivate var dismissGestureRecognizer: UITapGestureRecognizer?

    open var emailTapped: (() -> Void)?
    open var googleTapped: (() -> Void)?

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let vc = segue.destination as? NUXButtonViewController {
            buttonViewController = vc
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureButtonVC()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func configureButtonVC() {
        guard let buttonViewController = buttonViewController else {
            return
        }

        let loginTitle = NSLocalizedString("Sign up with Email", comment: "Button title. Tapping begins our normal sign up process.")
        let createTitle = NSLocalizedString("Sign up with Google", comment: "Button title. Tapping begins sign up using Google.")
        buttonViewController.setupTopButton(title: loginTitle, isPrimary: false) { [weak self] in
            self?.dismiss(animated: true)
            self?.emailTapped?()
        }
        buttonViewController.setupButtomButton(title: createTitle, isPrimary: false) { [weak self] in
            self?.dismiss(animated: true)
            self?.googleTapped?()
        }
        let termsButton = WPStyleGuide.termsButton()
        termsButton.on(.touchUpInside) { [weak self] button in
            guard let url = URL(string: WPAutomatticTermsOfServiceURL) else {
                return
            }
            let controller = WebViewControllerFactory.controller(url: url)
            let navController = RotationAwareNavigationViewController(rootViewController: controller)
            self?.present(navController, animated: true, completion: nil)
        }
        buttonViewController.stackView?.insertArrangedSubview(termsButton, at: 0)
        buttonViewController.backgroundColor = WPStyleGuide.lightGrey()
    }

    @IBAction func dismissTapped() {
        dismiss(animated: true)
    }
}
