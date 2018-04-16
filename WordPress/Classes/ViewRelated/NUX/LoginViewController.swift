/// View Controller for login-specific screens
class LoginViewController: NUXViewController, LoginFacadeDelegate {
    @IBOutlet var instructionLabel: UILabel?
    @objc var errorToPresent: Error?
    var restrictToWPCom = false

    lazy var loginFacade: LoginFacade = {
        let facade = LoginFacade()
        facade.delegate = self
        return facade
    }()

    var isJetpackLogin: Bool {
        return loginFields.meta.jetpackLogin
    }

    private var isSignUp: Bool {
        return loginFields.meta.emailMagicLinkSource == .signup
    }

    private var authenticationDelegate: WordPressAuthenticatorDelegate {
        guard let delegate = WordPressAuthenticator.shared.delegate else {
            fatalError()
        }

        return delegate
    }

    // MARK: Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        displayError(message: "")
        setupNavBarIcon()
        styleInstructions()

        if let error = errorToPresent {
            displayRemoteError(error)
        }
    }

    func didChangePreferredContentSize() {
        styleInstructions()
    }

    // MARK: - Setup and Configuration

    /// Places the WordPress logo in the navbar
    ///
    func setupNavBarIcon() {
        addWordPressLogoToNavController()
    }

    /// Configures instruction label font
    ///
    func styleInstructions() {
        instructionLabel?.font = WPStyleGuide.mediumWeightFont(forStyle: .subheadline)
        instructionLabel?.adjustsFontForContentSizeCategory = true
    }

    func configureViewLoading(_ loading: Bool) {
        configureSubmitButton(animating: loading)
        navigationItem.hidesBackButton = loading
    }

    /// Sets the text of the error label.
    func displayError(message: String) {
        guard message.count > 0 else {
            errorLabel?.isHidden = true
            return
        }
        errorLabel?.isHidden = false
        errorLabel?.text = message
    }

    private func mustShowLoginEpilogue() -> Bool {
        return isSignUp == false && authenticationDelegate.shouldPresentLoginEpilogue(isJetpackLogin: isJetpackLogin)
    }

    private func mustShowSignupEpilogue() -> Bool {
        return isSignUp && authenticationDelegate.shouldPresentSignupEpilogue()
    }


    // MARK: - Epilogue

    func showSignupEpilogue(for credentials: WordPressCredentials) {
        guard let navigationController = navigationController else {
            fatalError()
        }

        let service = loginFields.meta.googleUser.flatMap {
            return SocialService.google(user: $0)
        }

        authenticationDelegate.presentSignupEpilogue(in: navigationController, for: credentials, service: service)
    }

    func showLoginEpilogue(for credentials: WordPressCredentials) {
        guard let navigationController = navigationController else {
            fatalError()
        }

        authenticationDelegate.presentLoginEpilogue(in: navigationController, for: credentials) { [weak self] in
            self?.dismissBlock?(false)
        }
    }


    /// Validates what is entered in the various form fields and, if valid,
    /// proceeds with login.
    ///
    func validateFormAndLogin() {
        view.endEditing(true)
        displayError(message: "")

        // Is everything filled out?
        if !loginFields.validateFieldsPopulatedForSignin() {
            let errorMsg = NSLocalizedString("Please fill out all the fields", comment: "A short prompt asking the user to properly fill out all login fields.")
            displayError(message: errorMsg)

            return
        }

        configureViewLoading(true)

        loginFacade.signIn(with: loginFields)
    }

    /// Manages data transfer when seguing to a new VC
    ///
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let source = segue.source as? LoginViewController, let destination = segue.destination as? LoginViewController else {
            return
        }

        destination.loginFields = source.loginFields
        destination.restrictToWPCom = source.restrictToWPCom
        destination.dismissBlock = source.dismissBlock
        destination.errorToPresent = source.errorToPresent
    }

    // MARK: SigninWPComSyncHandler methods
    dynamic func finishedLogin(withUsername username: String, authToken: String, requiredMultifactorCode: Bool) {
        let credentials = WordPressCredentials.wpcom(username: username, authToken: authToken, isJetpackLogin: isJetpackLogin, multifactor: requiredMultifactorCode)

        syncWPComAndPresentEpilogue(credentials: credentials)
        linkSocialServiceIfNeeded(with: loginFields)
    }

    func configureStatusLabel(_ message: String) {
        // this is now a no-op, unless status labels return
    }

    /// Overridden here to direct these errors to the login screen's error label
    dynamic func displayRemoteError(_ error: Error) {
        configureViewLoading(false)

        let err = error as NSError
        guard err.code != 403 else {
            let message = NSLocalizedString("Whoops, something went wrong and we couldn't log you in. Please try again!", comment: "An error message shown when a wpcom user provides the wrong password.")
            displayError(message: message)
            return
        }

        displayError(err, sourceTag: sourceTag)
    }

    func needsMultifactorCode() {
        displayError(message: "")
        configureViewLoading(false)

        WordPressAuthenticator.track(.twoFactorCodeRequested)
        self.performSegue(withIdentifier: .show2FA, sender: self)
    }

    // Update safari stored credentials. Call after a successful sign in.
    ///
    func updateSafariCredentialsIfNeeded() {
        SafariCredentialsService.updateSafariCredentialsIfNeeded(with: loginFields)
    }
}


// MARK: - Sync Helpers
//
extension LoginViewController {


    /// Signals the Main App to synchronize the specified WordPress.com account. On completion, the epilogue will be pushed (if needed).
    ///
    func syncWPComAndPresentEpilogue(credentials: WordPressCredentials) {
        syncWPCom(credentials: credentials) { [weak self] in
            guard let `self` = self else {
                return
            }

            if self.mustShowSignupEpilogue() {
                self.showSignupEpilogue(for: credentials)
            } else if self.mustShowLoginEpilogue() {
                self.showLoginEpilogue(for: credentials)
            } else {
                self.dismiss()
            }
        }
    }

    /// TODO: @jlp Mar.19.2018. Officially support wporg, and rename to `sync(site)` + Update LoginSelfHostedViewController
    ///
    /// Signals the Main App to synchronize the specified WordPress.com account.
    ///
    private func syncWPCom(credentials: WordPressCredentials, completion: (() -> ())? = nil) {
        SafariCredentialsService.updateSafariCredentialsIfNeeded(with: loginFields)

        configureStatusLabel(NSLocalizedString("Getting account information", comment: "Alerts the user that wpcom account information is being retrieved."))

        authenticationDelegate.sync(credentials: credentials) { [weak self] _ in

            self?.configureStatusLabel("")
            self?.configureViewLoading(false)
            self?.trackSignIn(credentials: credentials)

            completion?()
        }
    }

    /// Tracks the SignIn Event
    ///
    func trackSignIn(credentials: WordPressCredentials) {
        var properties = [String: String]()

        switch credentials {
        case .wporg:
            break
        case .wpcom(_, _, _, let multifactor):
            properties = [
                "multifactor": multifactor.description,
                "dotcom_user": true.description
            ]
        }

        WordPressAuthenticator.track(.signedIn, properties: properties)
    }

    /// Links the current WordPress Account to a Social Service, if needed.
    ///
    func linkSocialServiceIfNeeded(with loginFields: LoginFields) {
        guard let socialService = loginFields.meta.socialService, socialService == SocialServiceName.google,
            let token = loginFields.meta.socialServiceIDToken else {
                return
        }

        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        service.connectToSocialService(socialService, serviceIDToken: token, success: {
            WordPressAuthenticator.track(.loginSocialConnectSuccess)
            WordPressAuthenticator.track(.loginSocialSuccess)
        }, failure: { error in
            DDLogError(error.description)
            WordPressAuthenticator.track(.loginSocialConnectFailure, error: error)
            // We're opting to let this call fail silently.
            // Our user has already successfully authenticated and can use the app --
            // connecting the social service isn't critical.  There's little to
            // be gained by displaying an error that can not currently be resolved
            // in the app and doing so might tarnish an otherwise satisfying login
            // experience.
            // If/when we add support for manually connecting/disconnecting services
            // we can revisit.
        })
    }
}


// MARK: - Handle changes in traitCollections. In particular, changes in Dynamic Type
//
extension LoginViewController {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            didChangePreferredContentSize()
        }
    }
}
