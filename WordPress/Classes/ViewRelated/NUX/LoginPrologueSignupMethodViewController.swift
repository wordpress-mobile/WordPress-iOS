class LoginPrologueSignupMethodViewController: UIViewController {
    private var buttonViewController: NUXButtonViewController?

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let vc = segue.destination as? NUXButtonViewController {
            buttonViewController = vc
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureButtonVC()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func configureButtonVC() {
        guard let buttonViewController = buttonViewController else {
            return
        }

        let loginTitle = NSLocalizedString("Sign up with Email", comment: "Button title.  Tapping begins our normal sign up process.")
        let createTitle = NSLocalizedString("Sign up with Google", comment: "Button title. Tapping begins sign up using Google.")
        buttonViewController.setupTopButton(title: loginTitle, isPrimary: false) { [weak self] in
            self?.performSegue(withIdentifier: NUXViewController.SegueIdentifier.showEmailLogin.rawValue, sender: self)
        }
        buttonViewController.setupButtomButton(title: createTitle, isPrimary: false) { [weak self] in
            // nil
        }
        let termsButton = WPStyleGuide.termsButton()
        buttonViewController.stackView?.insertArrangedSubview(termsButton, at: 0)
        if #available(iOS 11, *) {
            buttonViewController.stackView?.setCustomSpacing(0, after: termsButton)
        }
    }
}
