import Foundation

class LoginViewController: NUXAbstractViewController {
    @IBOutlet var errorLabel: UILabel?
    @IBOutlet var submitButton: NUXSubmitButton?

    lazy var loginFacade: LoginFacade = {
        let facade = LoginFacade()
        facade.delegate = self
        return facade
    }()

    /// Places the WordPress logo in the navbar
    ///
    func setupNavBarIcon() {
        let image = UIImage(named: "social-wordpress")
        let imageView = UIImageView(image: image?.imageWithTintColor(UIColor.white))
        navigationItem.titleView = imageView
    }

    /// Sets the text of the error label.
    ///
    func displayError(message: String) {
        errorLabel?.text = message
    }

    /// Configures the appearance and state of the submit button.
    ///
    func configureSubmitButton(animating: Bool) {
        submitButton?.showActivityIndicator(animating)
        submitButton?.isEnabled = enableSubmit(animating: animating)
    }

    /// Determines if the submit button should be enabled. Meant to be overridden in subclasses.
    ///
    open func enableSubmit(animating: Bool) -> Bool {
        return !animating
    }

    override func dismiss() {
        loginDismissal()
    }

    /// Validates what is entered in the various form fields and, if valid,
    /// proceeds with login.
    ///
    func validateFormAndLogin() {
        view.endEditing(true)
        displayError(message: "")

        // Is everything filled out?
        if !SigninHelpers.validateFieldsPopulatedForSignin(loginFields) {
            let errorMsg = NSLocalizedString("Please fill out all the fields", comment: "A short prompt asking the user to properly fill out all login fields.")
            displayError(message: errorMsg)

            return
        }

        configureViewLoading(true)

        loginFacade.signIn(with: loginFields)
    }
}

extension LoginViewController: SigninWPComSyncHandler, LoginFacadeDelegate {
    func configureStatusLabel(_ message: String) {
        // this is now a no-op, unless status labels return
    }

    /// Configure the view's loading state.
    ///
    /// - Parameter loading: True if the form should be configured to a "loading" state.
    ///
    func configureViewLoading(_ loading: Bool) {
        configureSubmitButton(animating: loading)
        navigationItem.hidesBackButton = loading
    }

    func finishedLogin(withUsername username: String!, authToken: String!, requiredMultifactorCode: Bool) {
        syncWPCom(username, authToken: authToken, requiredMultifactor: requiredMultifactorCode)
    }

    func displayRemoteError(_ error: Error!) {
        configureViewLoading(false)

        guard (error as NSError).code != 403 else {
            let message = NSLocalizedString("It seems like you've entered an incorrect password. Want to give it another try?", comment: "An error message shown when a wpcom user provides the wrong password.")
            displayError(message: message)
            return
        }

        displayError(error as NSError, sourceTag: sourceTag)
    }

    func needsMultifactorCode() {
        displayError(message: "")
        configureViewLoading(false)

        WPAppAnalytics.track(.twoFactorCodeRequested)
        self.performSegue(withIdentifier: .show2FA, sender: self)
    }

    // Update safari stored credentials. Call after a successful sign in.
    ///
    func updateSafariCredentialsIfNeeded() {
        SigninHelpers.updateSafariCredentialsIfNeeded(loginFields)
    }

    func loginDismissal() {
        self.performSegue(withIdentifier: .showEpilogue, sender: self)
    }
}
