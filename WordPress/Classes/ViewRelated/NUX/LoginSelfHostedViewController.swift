import UIKit
import WordPressShared

/// Part two of the self-hosted sign in flow. A valid site address should be acquired
/// before presenting this view controller.
///
class LoginSelfHostedViewController: NUXAbstractViewController, SigninKeyboardResponder, SigninWPComSyncHandler, LoginViewController {
    @IBOutlet var siteHeaderView: BlogDetailHeaderView!
    @IBOutlet var usernameField: WPWalkthroughTextField!
    @IBOutlet var passwordField: WPWalkthroughTextField!
    @IBOutlet var errorLabel: UILabel!
    @IBOutlet var submitButton: NUXSubmitButton!
    @IBOutlet var forgotPasswordButton: WPNUXSecondaryButton!
    @IBOutlet var bottomContentConstraint: NSLayoutConstraint?
    @IBOutlet var verticalCenterConstraint: NSLayoutConstraint?
    var onePasswordButton: UIButton!

    lazy var loginFacade: LoginFacade = {
        let facade = LoginFacade()
        facade.delegate = self
        return facade
    }()

    override var sourceTag: SupportSourceTag {
        get {
            return .wpOrgLogin
        }
    }

    var gravatarProfile: GravatarProfile?
    var userProfile: UserProfile?
    var blog: Blog?


    // MARK: - Lifecycle Methods


    override func viewDidLoad() {
        super.viewDidLoad()

        localizeControls()
        setupOnePasswordButtonIfNeeded()
        displayLoginMessage("")
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Update special case login fields.
        loginFields.userIsDotCom = false

        configureTextFields()
        configureSubmitButton(animating: false)
        configureViewForEditingIfNeeded()

        setupNavBarIcon()
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        registerForKeyboardEvents(keyboardWillShowAction: #selector(SigninEmailViewController.handleKeyboardWillShow(_:)),
                                  keyboardWillHideAction: #selector(SigninEmailViewController.handleKeyboardWillHide(_:)))


    }


    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterForKeyboardEvents()
    }


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        // Ensure that the user info is set on the epilogue vc.
        if let vc = segue.destination as? LoginEpilogueViewController {
            vc.epilogueUserInfo = epilogueUserInfo()
        }
    }


    // MARK: - Setup and Configuration


    /// let the storyboard's style stay
    override func setupStyles() {}


    /// Assigns localized strings to various UIControl defined in the storyboard.
    ///
    func localizeControls() {
        usernameField.placeholder = NSLocalizedString("Username", comment: "Username placeholder")
        passwordField.placeholder = NSLocalizedString("Password", comment: "Password placeholder")

        let submitButtonTitle = NSLocalizedString("Next", comment: "Title of a button. The text should be capitalized.").localizedCapitalized
        submitButton.setTitle(submitButtonTitle, for: UIControlState())
        submitButton.setTitle(submitButtonTitle, for: .highlighted)

        let forgotPasswordTitle = NSLocalizedString("Lost your password?", comment: "Title of a button. ")
        forgotPasswordButton.setTitle(forgotPasswordTitle, for: UIControlState())
        forgotPasswordButton.setTitle(forgotPasswordTitle, for: .highlighted)
    }


    /// Sets up a 1Password button if 1Password is available.
    ///
    func setupOnePasswordButtonIfNeeded() {
        WPStyleGuide.configureOnePasswordButtonForTextfield(usernameField,
                                                            target: self,
                                                            selector: #selector(SigninSelfHostedViewController.handleOnePasswordButtonTapped(_:)))
    }


    /// Configures the content of the text fields based on what is saved in `loginFields`.
    ///
    func configureTextFields() {
        usernameField.textInsets = WPStyleGuide.edgeInsetForLoginTextFields()
        passwordField.textInsets = WPStyleGuide.edgeInsetForLoginTextFields()
        usernameField.text = loginFields.username
        passwordField.text = loginFields.password
    }


    /// Configures the appearance and state of the forgot password button.
    ///
    func configureForgotPasswordButton() {
        forgotPasswordButton.isEnabled = !submitButton.isAnimating
    }


    /// Configures the appearance and state of the submit button.
    ///
    func configureSubmitButton(animating: Bool) {
        submitButton.showActivityIndicator(animating)

        submitButton.isEnabled = (
            !animating &&
                !loginFields.username.isEmpty &&
                !loginFields.password.isEmpty
        )
    }


    /// Sets the view's state to loading or not loading.
    ///
    /// - Parameter loading: True if the form should be configured to a "loading" state.
    ///
    func configureViewLoading(_ loading: Bool) {
        usernameField.isEnabled = !loading
        passwordField.isEnabled = !loading

        configureSubmitButton(animating: loading)
        configureForgotPasswordButton()
        navigationItem.hidesBackButton = loading
    }


    /// Configure the view for an editing state. Should only be called from viewWillAppear
    /// as this method skips animating any change in height.
    ///
    func configureViewForEditingIfNeeded() {
        // Check the helper to determine whether an editiing state should be assumed.
        adjustViewForKeyboard(SigninEditingState.signinEditingStateActive)
        if SigninEditingState.signinEditingStateActive {
            usernameField.becomeFirstResponder()
        }
    }


    /// Noop. Required by wpcom sync handler.
    ///
    func configureStatusLabel(_ message: String) {
    }


    // MARK: - Instance Methods


    /// Noop.  Required by the SigninWPComSyncHandler protocol but the self-hosted
    /// controller's implementation does not use safari saved credentials.
    ///
    func updateSafariCredentialsIfNeeded() {
    }


    /// Validates what is entered in the various form fields and, if valid,
    /// proceeds with the submit action.
    ///
    func validateForm() {
        view.endEditing(true)
        displayError(message: "")

        // Is everything filled out?
        if !SigninHelpers.validateFieldsPopulatedForSignin(loginFields) {
            WPError.showAlert(withTitle: NSLocalizedString("Error", comment: "Title of an error message"),
                              message: NSLocalizedString("Please fill out all the fields", comment: "A short prompt asking the user to properly fill out all login fields."),
                              withSupportButton: false)

            return
        }

        configureViewLoading(true)

        loginFacade.login(with: loginFields)
    }


    /// Sets the text of the error label.
    ///
    func displayError(message: String) {
        errorLabel.text = message
    }


    /// Advances to the epilogue view controller once the self-hosted site has been added.
    ///
    func showEpilogue() {
        configureViewLoading(false)
        performSegue(withIdentifier: .showEpilogue, sender: self)
    }


    // MARK: - Epilogue: Gravatar and User Profile Acquisition


    /// Returns an instance of LoginEpilogueUserInfo composed from
    /// a user's gravatar profile, and/or self-hosted blog profile.
    ///
    func epilogueUserInfo() -> LoginEpilogueUserInfo {
        var info = LoginEpilogueUserInfo()
        if let profile = gravatarProfile {
            info.gravatarUrl = profile.thumbnailUrl
            info.fullName = profile.displayName
        }

        // Whatever is in user profile trumps whatever is in the gravatar profile.
        if let profile = userProfile {
            info.username = profile.username
            info.fullName = profile.displayName
            info.email = profile.email
        }

        info.blog = blog

        return info
    }


    /// Fetches the user's profile data from their blog. If success, it next queries
    /// the user's gravatar profile data passing the completion block.
    ///
    func fetchUserProfileInfo(blog: Blog, completion: @escaping (() -> Void )) {
        let service = UsersService()
        service.fetchProfile(blog: blog, success: { [weak self] (profile) in
            self?.userProfile = profile
            self?.fetchGravatarProfileInfo(email: profile.email, completion: completion)
            }, failure: { [weak self] (_) in
                self?.showEpilogue()
        })
    }


    /// Queries the user's gravatar profile data. On success calls completion.
    ///
    func fetchGravatarProfileInfo(email: String, completion: @escaping (() -> Void )) {
        let service = GravatarService()
        service.fetchProfile(email, success: { [weak self] (profile) in
            self?.gravatarProfile = profile
            completion()
            }, failure: { [weak self] (_) in
                self?.showEpilogue()
        })
    }


    // MARK: - Actions


    @IBAction func handleTextFieldDidChange(_ sender: UITextField) {
        loginFields.username = usernameField.nonNilTrimmedText()
        loginFields.password = passwordField.nonNilTrimmedText()

        configureForgotPasswordButton()
        configureSubmitButton(animating: false)
    }


    @IBAction func handleSubmitButtonTapped(_ sender: UIButton) {
        validateForm()
    }


    func handleOnePasswordButtonTapped(_ sender: UIButton) {
        view.endEditing(true)

        SigninHelpers.fetchOnePasswordCredentials(self, sourceView: sender, loginFields: loginFields) { [unowned self] (loginFields) in
            self.usernameField.text = loginFields.username
            self.passwordField.text = loginFields.password
            self.validateForm()
        }
    }


    @IBAction func handleForgotPasswordButtonTapped(_ sender: UIButton) {
        SigninHelpers.openForgotPasswordURL(loginFields)
    }


    // MARK: - Keyboard Notifications


    func handleKeyboardWillShow(_ notification: Foundation.Notification) {
        keyboardWillShow(notification)
    }


    func handleKeyboardWillHide(_ notification: Foundation.Notification) {
        keyboardWillHide(notification)
    }
}


extension LoginSelfHostedViewController: LoginFacadeDelegate {

    func finishedLogin(withUsername username: String!, authToken: String!, requiredMultifactorCode: Bool) {
        syncWPCom(username, authToken: authToken, requiredMultifactor: requiredMultifactorCode)
    }


    func finishedLogin(withUsername username: String!, password: String!, xmlrpc: String!, options: [AnyHashable: Any]!) {
        displayLoginMessage("")

        BlogSyncFacade().syncBlog(withUsername: username, password: password, xmlrpc: xmlrpc, options: options) { [weak self] in
            NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: SigninHelpers.WPSigninDidFinishNotification), object: nil)

            let context = ContextManager.sharedInstance().mainContext
            let service = BlogService(managedObjectContext: context)
            guard let blog = service.findBlog(withXmlrpc: xmlrpc, andUsername: username) else {
                assertionFailure("A blog was just added but was not found in core data.")
                // Skip showing the epilogue in this situation. Since there will
                // be no blog to present to the user the screen is likly to be
                // confusing. Instead just dismiss.
                self?.dismiss()
                return
            }

            RecentSitesService().touch(blog: blog)
            self?.blog = blog
            self?.fetchUserProfileInfo(blog: blog, completion: {
                self?.showEpilogue()
            })
        }
    }


    func displayLoginMessage(_ message: String!) {
        configureForgotPasswordButton()
    }


    func displayRemoteError(_ error: Error!) {
        displayLoginMessage("")
        configureViewLoading(false)
        let err = error as NSError
        if err.code == 403 {
            displayError(message: NSLocalizedString("It looks like this username/password isn't associated with this site.", comment: "An error message shown during log in when the username or password is incorrect."))
        } else {
            displayError(error as NSError, sourceTag: sourceTag)
        }
    }


    func needsMultifactorCode() {
        configureViewLoading(false)

        WPAppAnalytics.track(.twoFactorCodeRequested)
        // Credentials were good but a 2fa code is needed.
        loginFields.shouldDisplayMultifactor = true // technically not needed

        performSegue(withIdentifier: .show2FA, sender: self)
    }
}


extension LoginSelfHostedViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            validateForm()
        }
        return true
    }
}

