import UIKit
import WordPressShared

/// Part two of the self-hosted sign in flow. A valid site address should be acquired
/// before presenting this view controller.
///
class LoginSelfHostedViewController: LoginViewController, NUXKeyboardResponder {
    @IBOutlet var siteHeaderView: SiteInfoHeaderView!
    @IBOutlet var siteAddressStackView: UIStackView!
    @IBOutlet var siteAddressLabel: UILabel!
    @IBOutlet var usernameField: WPWalkthroughTextField!
    @IBOutlet var passwordField: WPWalkthroughTextField!
    @IBOutlet var forgotPasswordButton: WPNUXSecondaryButton!
    @IBOutlet var bottomContentConstraint: NSLayoutConstraint?
    @IBOutlet var verticalCenterConstraint: NSLayoutConstraint?
    @objc var onePasswordButton: UIButton!
    override var sourceTag: WordPressSupportSourceTag {
        get {
            return .loginUsernamePassword
        }
    }

    override var loginFields: LoginFields {
        didSet {
            // Clear the username & password (if any) from LoginFields
            loginFields.username = ""
            loginFields.password = ""
        }
    }

    var gravatarProfile: GravatarProfile?
    var userProfile: UserProfile?
    @objc var blog: Blog?


    // MARK: - Lifecycle Methods


    override func viewDidLoad() {
        super.viewDidLoad()

        configureHeader()
        localizeControls()
        setupOnePasswordButtonIfNeeded()
        displayLoginMessage("")
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Update special case login fields.
        loginFields.meta.userIsDotCom = false

        configureTextFields()
        configureSubmitButton(animating: false)
        configureViewForEditingIfNeeded()

        setupNavBarIcon()
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        registerForKeyboardEvents(keyboardWillShowAction: #selector(handleKeyboardWillShow(_:)),
                                  keyboardWillHideAction: #selector(handleKeyboardWillHide(_:)))

        WordPressAuthenticator.post(event: .loginUsernamePasswordFormViewed)
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
            vc.jetpackLogin = loginFields.meta.jetpackLogin
        }
    }


    // MARK: - Setup and Configuration


    /// Assigns localized strings to various UIControl defined in the storyboard.
    ///
    @objc func localizeControls() {
        usernameField.placeholder = NSLocalizedString("Username", comment: "Username placeholder")
        passwordField.placeholder = NSLocalizedString("Password", comment: "Password placeholder")

        let submitButtonTitle = NSLocalizedString("Next", comment: "Title of a button. The text should be capitalized.").localizedCapitalized
        submitButton?.setTitle(submitButtonTitle, for: UIControlState())
        submitButton?.setTitle(submitButtonTitle, for: .highlighted)

        let forgotPasswordTitle = NSLocalizedString("Lost your password?", comment: "Title of a button. ")
        forgotPasswordButton.setTitle(forgotPasswordTitle, for: UIControlState())
        forgotPasswordButton.setTitle(forgotPasswordTitle, for: .highlighted)
        forgotPasswordButton.titleLabel?.numberOfLines = 0
    }


    /// Sets up a 1Password button if 1Password is available.
    ///
    @objc func setupOnePasswordButtonIfNeeded() {
        WPStyleGuide.configureOnePasswordButtonForTextfield(usernameField,
                                                            target: self,
                                                            selector: #selector(handleOnePasswordButtonTapped(_:)))
    }


    /// Configures the content of the text fields based on what is saved in `loginFields`.
    ///
    @objc func configureTextFields() {
        usernameField.text = loginFields.username
        passwordField.text = loginFields.password
        passwordField.contentInsets = WPStyleGuide.edgeInsetForLoginTextFields()
        usernameField.contentInsets = WPStyleGuide.edgeInsetForLoginTextFields()
    }


    /// Configures the appearance and state of the forgot password button.
    ///
    @objc func configureForgotPasswordButton() {
        forgotPasswordButton.isEnabled = enableSubmit(animating: false)
    }


    /// Configures the appearance and state of the submit button.
    ///
    override func configureSubmitButton(animating: Bool) {
        submitButton?.showActivityIndicator(animating)

        submitButton?.isEnabled = (
            !animating &&
                !loginFields.username.isEmpty &&
                !loginFields.password.isEmpty
        )
    }


    /// Sets the view's state to loading or not loading.
    ///
    /// - Parameter loading: True if the form should be configured to a "loading" state.
    ///
    override func configureViewLoading(_ loading: Bool) {
        usernameField.isEnabled = !loading
        passwordField.isEnabled = !loading

        configureSubmitButton(animating: loading)
        configureForgotPasswordButton()
        navigationItem.hidesBackButton = loading
    }


    /// Configure the view for an editing state. Should only be called from viewWillAppear
    /// as this method skips animating any change in height.
    ///
    @objc func configureViewForEditingIfNeeded() {
        // Check the helper to determine whether an editiing state should be assumed.
        adjustViewForKeyboard(SigninEditingState.signinEditingStateActive)
        if SigninEditingState.signinEditingStateActive {
            usernameField.becomeFirstResponder()
        }
    }


    /// Configure the site header.
    ///
    @objc func configureHeader() {
        if let siteInfo = loginFields.meta.siteInfo {
            configureBlogDetailHeaderView(siteInfo: siteInfo)
        } else {
            configureSiteAddressHeader()
        }
    }


    /// Configure the site header to show the BlogDetailsHeaderView
    ///
    @objc func configureBlogDetailHeaderView(siteInfo: SiteInfo) {
        siteAddressStackView.isHidden = true
        siteHeaderView.isHidden = false

        let siteAddress = sanitizedSiteAddress(siteAddress: siteInfo.url)
        siteHeaderView.setTitleText(siteInfo.name)
        siteHeaderView.setSubtitleText(siteAddress)
        siteHeaderView.loadImage(atPath: siteInfo.icon)
    }


    /// Configure the site header to show the site address label.
    ///
    @objc func configureSiteAddressHeader() {
        siteAddressStackView.isHidden = false
        siteHeaderView.isHidden = true

        siteAddressLabel.text = sanitizedSiteAddress(siteAddress: loginFields.siteAddress)
    }


    /// Sanitize and format the site address we show to users.
    ///
    @objc func sanitizedSiteAddress(siteAddress: String) -> String {
        let baseSiteUrl = WordPressAuthenticator.baseSiteURL(string: siteAddress) as NSString
        if let str = baseSiteUrl.components(separatedBy: "://").last {
            return str
        }
        return siteAddress
    }


    // MARK: - Instance Methods


    /// Noop.  Required by the SigninWPComSyncHandler protocol but the self-hosted
    /// controller's implementation does not use safari saved credentials.
    ///
    override func updateSafariCredentialsIfNeeded() {
    }


    /// Validates what is entered in the various form fields and, if valid,
    /// proceeds with the submit action.
    ///
    @objc func validateForm() {
        validateFormAndLogin()
    }


    /// Advances to the epilogue view controller once the self-hosted site has been added.
    ///
    @objc func showEpilogue() {
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
    @objc func fetchUserProfileInfo(blog: Blog, completion: @escaping (() -> Void )) {
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
    @objc func fetchGravatarProfileInfo(email: String, completion: @escaping (() -> Void )) {
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


    @objc func handleOnePasswordButtonTapped(_ sender: UIButton) {
        view.endEditing(true)

        WordPressAuthenticator.fetchOnePasswordCredentials(self, sourceView: sender, loginFields: loginFields) { [unowned self] (loginFields) in
            self.usernameField.text = loginFields.username
            self.passwordField.text = loginFields.password
            self.validateForm()
        }
    }


    @IBAction func handleForgotPasswordButtonTapped(_ sender: UIButton) {
        WordPressAuthenticator.openForgotPasswordURL(loginFields)
        WordPressAuthenticator.post(event: .loginForgotPasswordClicked)
    }


    // MARK: - Keyboard Notifications


    @objc func handleKeyboardWillShow(_ notification: Foundation.Notification) {
        keyboardWillShow(notification)
    }


    @objc func handleKeyboardWillHide(_ notification: Foundation.Notification) {
        keyboardWillHide(notification)
    }
}


extension LoginSelfHostedViewController {

    override func finishedLogin(withUsername username: String!, authToken: String!, requiredMultifactorCode: Bool) {
        syncWPCom(username, authToken: authToken, requiredMultifactor: requiredMultifactorCode)
    }


    func finishedLogin(withUsername username: String!, password: String!, xmlrpc: String!, options: [AnyHashable: Any]!) {
        displayLoginMessage("")

        BlogSyncFacade().syncBlog(withUsername: username, password: password, xmlrpc: xmlrpc, options: options) { [weak self] in
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
            NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: WordPressAuthenticator.WPSigninDidFinishNotification), object: nil)

            self?.blog = blog
            self?.fetchUserProfileInfo(blog: blog, completion: {
                self?.showEpilogue()
            })
        }
    }


    func displayLoginMessage(_ message: String!) {
        configureForgotPasswordButton()
    }


    override func displayRemoteError(_ error: Error!) {
        displayLoginMessage("")
        configureViewLoading(false)
        let err = error as NSError
        if err.code == 403 {
            displayError(message: NSLocalizedString("It looks like this username/password isn't associated with this site.", comment: "An error message shown during log in when the username or password is incorrect."))
        } else {
            displayError(error as NSError, sourceTag: sourceTag)
        }
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
