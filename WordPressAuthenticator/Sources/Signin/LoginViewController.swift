import WordPressShared
import WordPressKit

/// View Controller for login-specific screens
open class LoginViewController: NUXViewController, LoginFacadeDelegate {
    @IBOutlet var instructionLabel: UILabel?
    @objc var errorToPresent: Error?

    let tracker = AuthenticatorAnalyticsTracker.shared

    /// Constraints on the table view container.
    /// Used to adjust the table width in unified views.
    @IBOutlet var tableViewLeadingConstraint: NSLayoutConstraint?
    @IBOutlet var tableViewTrailingConstraint: NSLayoutConstraint?
    var defaultTableViewMargin: CGFloat = 0

    lazy var loginFacade: LoginFacade = {
        let configuration = WordPressAuthenticator.shared.configuration
        let facade = LoginFacade(dotcomClientID: configuration.wpcomClientId,
                                 dotcomSecret: configuration.wpcomSecret,
                                 userAgent: configuration.userAgent)
        facade.delegate = self
        return facade
    }()

    var isJetpackLogin: Bool {
        return loginFields.meta.jetpackLogin
    }

    private var isSignUp: Bool {
        return loginFields.meta.emailMagicLinkSource == .signup
    }

    var authenticationDelegate: WordPressAuthenticatorDelegate {
        guard let delegate = WordPressAuthenticator.shared.delegate else {
            fatalError()
        }

        return delegate
    }

    open override var preferredStatusBarStyle: UIStatusBarStyle {
        // Set to the old style as the default.
        // Each VC in the unified flows needs to override this to use the unified style.
        return WordPressAuthenticator.shared.style.statusBarStyle
    }

    // MARK: Lifecycle Methods

    override open func viewDidLoad() {
        super.viewDidLoad()

        displayError(message: "")
        styleNavigationBar(forUnified: true)
        styleBackground()
        styleInstructions()

        if let error = errorToPresent {
            displayRemoteError(error)
            errorToPresent = nil
        }
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if isBeingDismissedInAnyWay {
            tracker.track(click: .dismiss)
        }
    }

    func didChangePreferredContentSize() {
        styleInstructions()
    }

    // MARK: - Setup and Configuration

    /// Styles the view's background color. Defaults to WPStyleGuide.lightGrey()
    ///
    func styleBackground() {
        view.backgroundColor = WordPressAuthenticator.shared.style.viewControllerBackgroundColor
    }

    /// Configures instruction label font
    ///
    func styleInstructions() {
        instructionLabel?.font = WPStyleGuide.mediumWeightFont(forStyle: .subheadline)
        instructionLabel?.adjustsFontForContentSizeCategory = true
        instructionLabel?.textColor = WordPressAuthenticator.shared.style.instructionColor
    }

    func configureViewLoading(_ loading: Bool) {
        configureSubmitButton(animating: loading)
        navigationItem.hidesBackButton = loading
    }

    /// Sets the text of the error label.
    ///
    /// - Parameter message: The message to display in the `errorLabel`. If empty, the `errorLabel`
    ///     will be hidden.
    /// - Parameter moveVoiceOverFocus: If `true`, moves the VoiceOver focus to the `errorLabel`.
    ///     You will want to set this to `true` if the error was caused after pressing a button
    ///     (e.g. Next button).
    func displayError(message: String, moveVoiceOverFocus: Bool = false) {
        guard message.count > 0 else {
            errorLabel?.isHidden = true
            return
        }

        tracker.track(failure: message)

        errorLabel?.isHidden = false
        errorLabel?.text = message
        errorToPresent = nil

        if moveVoiceOverFocus, let errorLabel {
            UIAccessibility.post(notification: .layoutChanged, argument: errorLabel)
        }
    }

    private func mustShowLoginEpilogue() -> Bool {
        return isSignUp == false && authenticationDelegate.shouldPresentLoginEpilogue(isJetpackLogin: isJetpackLogin)
    }

    private func mustShowSignupEpilogue() -> Bool {
        return isSignUp && authenticationDelegate.shouldPresentSignupEpilogue()
    }

    // MARK: - Epilogue

    func showSignupEpilogue(for credentials: AuthenticatorCredentials) {
        guard let navigationController else {
            fatalError()
        }

        authenticationDelegate.presentSignupEpilogue(
            in: navigationController,
            for: credentials,
            socialUser: loginFields.meta.socialUser
        )
    }

    func showLoginEpilogue(for credentials: AuthenticatorCredentials) {
        guard let navigationController else {
            fatalError()
        }

        authenticationDelegate.presentLoginEpilogue(in: navigationController,
                                                    for: credentials,
                                                    source: WordPressAuthenticator.shared.signInSource) { [weak self] in
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
            let errorMsg = LocalizedText.missingInfoError
            displayError(message: errorMsg)

            return
        }

        configureViewLoading(true)

        loginFacade.signIn(with: loginFields)
    }

    // MARK: SigninWPComSyncHandler methods
    dynamic open func finishedLogin(withAuthToken authToken: String, requiredMultifactorCode: Bool) {
        let wpcom = WordPressComCredentials(authToken: authToken, isJetpackLogin: isJetpackLogin, multifactor: requiredMultifactorCode, siteURL: loginFields.siteAddress)
        let credentials = AuthenticatorCredentials(wpcom: wpcom)

        syncWPComAndPresentEpilogue(credentials: credentials)

        linkSocialServiceIfNeeded(loginFields: loginFields, wpcomAuthToken: authToken)
    }

    func configureStatusLabel(_ message: String) {
        // this is now a no-op, unless status labels return
    }

    /// Overridden here to direct these errors to the login screen's error label
    dynamic open func displayRemoteError(_ error: Error) {
        configureViewLoading(false)
        let err = error as NSError
        guard err.code != 403 else {
            let message = LocalizedText.loginError
            displayError(message: message)
            return
        }

        displayError(err, sourceTag: sourceTag)
    }

    open func needsMultifactorCode() {
        displayError(message: "")
        configureViewLoading(false)

        if tracker.shouldUseLegacyTracker() {
            WordPressAuthenticator.track(.twoFactorCodeRequested)
        }

        let unifiedAuthEnabled = WordPressAuthenticator.shared.configuration.enableUnifiedAuth
        let unifiedGoogle = unifiedAuthEnabled && loginFields.meta.socialService == .google
        let unifiedApple = unifiedAuthEnabled && loginFields.meta.socialService == .apple
        let unifiedSiteAddress = unifiedAuthEnabled && !loginFields.siteAddress.isEmpty
        let unifiedWordPress = unifiedAuthEnabled && loginFields.meta.userIsDotCom

        guard unifiedGoogle || unifiedApple || unifiedSiteAddress || unifiedWordPress else {
            presentLogin2FA()
            return
        }

        // Make sure we don't provide any old nonce information when we are required to present only the multi-factor code option.
        loginFields.nonceInfo = nil
        loginFields.nonceUserID = 0

        presentUnified2FA()
    }

    private enum LocalizedText {
        static let loginError = NSLocalizedString("Whoops, something went wrong and we couldn't log you in. Please try again!", comment: "An error message shown when a wpcom user provides the wrong password.")
        static let missingInfoError = NSLocalizedString("Please fill out all the fields", comment: "A short prompt asking the user to properly fill out all login fields.")
        static let gettingAccountInfo = NSLocalizedString("Getting account information", comment: "Alerts the user that wpcom account information is being retrieved.")
    }
}

// MARK: - View FLow

extension LoginViewController {
    func presentEpilogue(credentials: AuthenticatorCredentials) {
        if mustShowSignupEpilogue() {
            showSignupEpilogue(for: credentials)
        } else if mustShowLoginEpilogue() {
            showLoginEpilogue(for: credentials)
        } else {
            dismiss()
        }
    }
}

// MARK: - Sync Helpers

extension LoginViewController {

    /// Signals the Main App to synchronize the specified WordPress.com account. On completion, the epilogue will be pushed (if needed).
    ///
    func syncWPComAndPresentEpilogue(
        credentials: AuthenticatorCredentials,
        completion: (() -> Void)? = nil) {

        configureStatusLabel(LocalizedText.gettingAccountInfo)

        syncWPCom(credentials: credentials) { [weak self] in
            guard let self else {
                return
            }

            completion?()

            self.presentEpilogue(credentials: credentials)
            self.configureStatusLabel("")
            self.configureViewLoading(false)
            self.trackSignIn(credentials: credentials)
        }
    }

    /// Signals the Main App to synchronize the specified WordPress.com account.
    ///
    func syncWPCom(credentials: AuthenticatorCredentials, completion: (() -> Void)? = nil) {
        authenticationDelegate.sync(credentials: credentials) {
            completion?()
        }
    }

    /// Tracks the SignIn Event
    ///
    func trackSignIn(credentials: AuthenticatorCredentials) {
        var properties = [String: String]()

        if let wpcom = credentials.wpcom {
            properties = [
                "multifactor": wpcom.multifactor.description,
                "dotcom_user": true.description
            ]
        }

        // This stat is part of a funnel that provides critical information.  Please
        // consult with your lead before removing this event.
        WordPressAuthenticator.track(.signedIn, properties: properties)
        tracker.track(step: .success)
    }

    /// Links the current WordPress Account to a Social Service (if possible!!).
    ///
    func linkSocialServiceIfNeeded(loginFields: LoginFields, wpcomAuthToken: String) {
        guard let serviceName = loginFields.meta.socialService, let serviceToken = loginFields.meta.socialServiceIDToken else {
            return
        }

        linkSocialService(serviceName: serviceName,
                          serviceToken: serviceToken,
                          wpcomAuthToken: wpcomAuthToken,
                          appleConnectParameters: loginFields.parametersForSignInWithApple)
    }

    /// Links the current WordPress Account to a Social Service.
    ///
    func linkSocialService(serviceName: SocialServiceName,
                           serviceToken: String,
                           wpcomAuthToken: String,
                           appleConnectParameters: [String: AnyObject]? = nil) {
        let service = WordPressComAccountService()
        service.connect(wpcomAuthToken: wpcomAuthToken,
                        serviceName: serviceName,
                        serviceToken: serviceToken,
                        connectParameters: appleConnectParameters,
                        success: {
                            // This stat is part of a funnel that provides critical information.  Please
                            // consult with your lead before removing this event.
                            let source = appleConnectParameters != nil ? "apple" : "google"
                            WordPressAuthenticator.track(.signedIn, properties: ["source": source])

                            if AuthenticatorAnalyticsTracker.shared.shouldUseLegacyTracker() {
                                WordPressAuthenticator.track(.loginSocialConnectSuccess)
                                WordPressAuthenticator.track(.loginSocialSuccess)
                            }
        }, failure: { error in
            WPAuthenticatorLogError("Social Link Error: \(error)")
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

// MARK: - Handle View Changes
//
extension LoginViewController {

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Update Dynamic Type
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            didChangePreferredContentSize()
        }

        // Update Table View size
        setTableViewMargins(forWidth: view.frame.width)
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        setTableViewMargins(forWidth: size.width)
    }

    /// Resize the table view based on trait collection.
    /// Used only in unified views.
    ///
    func setTableViewMargins(forWidth viewWidth: CGFloat) {
        guard let tableViewLeadingConstraint,
            let tableViewTrailingConstraint else {
                return
        }

        guard traitCollection.horizontalSizeClass == .regular &&
            traitCollection.verticalSizeClass == .regular else {
                tableViewLeadingConstraint.constant = defaultTableViewMargin
                tableViewTrailingConstraint.constant = defaultTableViewMargin
                return
        }

        let marginMultiplier = UIDevice.current.orientation.isLandscape ?
            TableViewMarginMultipliers.ipadLandscape :
            TableViewMarginMultipliers.ipadPortrait

        let margin = viewWidth * marginMultiplier

        tableViewLeadingConstraint.constant = margin
        tableViewTrailingConstraint.constant = margin
    }

    private enum TableViewMarginMultipliers {
        static let ipadPortrait: CGFloat = 0.1667
        static let ipadLandscape: CGFloat = 0.25
    }

}

// MARK: - Social Sign In Handling

extension LoginViewController {

    func removeGoogleWaitingView() {
        // Remove the Waiting for Google view so it doesn't reappear when backing through the navigation stack.
        navigationController?.viewControllers.removeAll(where: { $0 is GoogleAuthViewController })
    }

    func signInAppleAccount() {
        guard let token = loginFields.meta.socialServiceIDToken else {
            WordPressAuthenticator.track(.loginSocialButtonFailure, properties: ["source": SocialServiceName.apple.rawValue])
            configureViewLoading(false)
            return
        }

        loginFacade.loginToWordPressDotCom(withSocialIDToken: token, service: SocialServiceName.apple.rawValue)
    }

    // Used by SIWA when logging with with a passwordless, 2FA account.
    //
    func socialNeedsMultifactorCode(forUserID userID: Int, andNonceInfo nonceInfo: SocialLogin2FANonceInfo) {
        loginFields.nonceInfo = nonceInfo
        loginFields.nonceUserID = userID

        guard WordPressAuthenticator.shared.configuration.enableUnifiedAuth else {
            presentLogin2FA()
            return
        }

        presentUnified2FA()
    }

    private func presentLogin2FA() {
        var properties = [AnyHashable: Any]()
        if let service = loginFields.meta.socialService?.rawValue {
            properties["source"] = service
        }

        if tracker.shouldUseLegacyTracker() {
            WordPressAuthenticator.track(.loginSocial2faNeeded, properties: properties)
        }

        guard let vc = Login2FAViewController.instantiate(from: .login) else {
            WPAuthenticatorLogError("Failed to navigate from LoginViewController to Login2FAViewController")
            return
        }

        vc.loginFields = loginFields
        vc.dismissBlock = dismissBlock
        vc.errorToPresent = errorToPresent

        navigationController?.pushViewController(vc, animated: true)
    }

    private func presentUnified2FA() {

        guard let vc = TwoFAViewController.instantiate(from: .twoFA) else {
            WPAuthenticatorLogError("Failed to navigate from LoginViewController to TwoFAViewController")
            return
        }

        vc.dismissBlock = dismissBlock
        vc.loginFields = loginFields
        navigationController?.pushViewController(vc, animated: true)
    }

}

// MARK: - LoginSocialError delegate methods

extension LoginViewController: LoginSocialErrorViewControllerDelegate {

    func retryWithEmail() {
        loginFields.username = ""
        cleanupAfterSocialErrors()
        navigationController?.popToRootViewController(animated: true)
    }

    func retryWithAddress() {
        cleanupAfterSocialErrors()
        loginToSelfHostedSite()
    }

    func retryAsSignup() {
        cleanupAfterSocialErrors()

        if let controller = SignupEmailViewController.instantiate(from: .signup) {
            controller.loginFields = loginFields
            navigationController?.pushViewController(controller, animated: true)
        }
    }

    func errorDismissed() {
        loginFields.username = ""
        navigationController?.popToRootViewController(animated: true)
    }

    private func cleanupAfterSocialErrors() {
        dismiss(animated: true) {}
    }

    /// Displays the self-hosted login form.
    ///
    @objc func loginToSelfHostedSite() {
        guard WordPressAuthenticator.shared.configuration.enableUnifiedAuth else {
            presentSelfHostedView()
            return
        }

        presentUnifiedSiteAddressView()
    }

    /// Navigates to the unified site address login flow.
    ///
    func presentUnifiedSiteAddressView() {
        guard let vc = SiteAddressViewController.instantiate(from: .siteAddress) else {
            WPAuthenticatorLogError("Failed to navigate from LoginViewController to SiteAddressViewController")
            return
        }

        navigationController?.pushViewController(vc, animated: true)
    }

    /// Navigates to the old self-hosted login flow.
    ///
    func presentSelfHostedView() {
        guard let vc = LoginSiteAddressViewController.instantiate(from: .login) else {
            WPAuthenticatorLogError("Failed to navigate from LoginViewController to LoginSiteAddressViewController")
            return
        }

        vc.loginFields = loginFields
        vc.dismissBlock = dismissBlock
        vc.errorToPresent = errorToPresent

        navigationController?.pushViewController(vc, animated: true)
    }

}
