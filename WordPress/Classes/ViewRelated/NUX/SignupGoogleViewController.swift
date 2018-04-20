import GoogleSignIn
import SVProgressHUD

/// View controller that handles the google signup code
class SignupGoogleViewController: LoginViewController {

    // MARK: - Properties

    private var hasShownGoogle = false
    @IBOutlet var titleLabel: UILabel!

    override var sourceTag: WordPressSupportSourceTag {
        get {
            return .wpComSignupWaitingForGoogle
        }
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel?.text = NSLocalizedString("Waiting for Google to complete…", comment: "Message shown on screen while waiting for Google to finish its signup process.")
        WordPressAuthenticator.track(.createAccountInitiated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        displayGoogleSingleSignOnIfNeeded()
    }

    private func displayGoogleSingleSignOnIfNeeded() {
        guard !hasShownGoogle else {
            return
        }

        displayGoogleSingleSignOn()
        hasShownGoogle = true
    }

    private func displayGoogleSingleSignOn() {
        GIDSignIn.sharedInstance().disconnect()

        // Flag this as a social sign in.
        loginFields.meta.socialService = .google

        // Configure all the things and sign in.
        guard let googleSSO = GIDSignIn.sharedInstance() else {
            DDLogError("Something is very, very, very off. Well done, Google.")
            return
        }

        googleSSO.delegate = self
        googleSSO.uiDelegate = self
        googleSSO.clientID = WordPressAuthenticator.shared.configuration.googleLoginClientId
        googleSSO.serverClientID = WordPressAuthenticator.shared.configuration.googleLoginServerClientId

        googleSSO.signIn()
    }
}


// MARK: - GIDSignInDelegate

extension SignupGoogleViewController: GIDSignInDelegate {

    func sign(_ signIn: GIDSignIn?, didSignInFor user: GIDGoogleUser?, withError error: Error?) {
        GIDSignIn.sharedInstance().disconnect()

        guard let googleUser = user, let googleToken = googleUser.authentication.idToken, let googleEmail = googleUser.profile.email else {
            WordPressAuthenticator.track(.signupSocialButtonFailure, error: error)
            self.navigationController?.popViewController(animated: true)
            return
        }

        updateLoginFields(googleUser: googleUser, googleToken: googleToken, googleEmail: googleEmail)
        createWordPressComUser(googleUser: googleUser, googleToken: googleToken, googleEmail: googleEmail)
    }
}


// MARK: - WordPress.com Account Creation Methods
//
private extension SignupGoogleViewController {

    /// TODO: Not cool with this. Let's refactor LoginFields, when time permits.
    ///
    func updateLoginFields(googleUser: GIDGoogleUser, googleToken: String, googleEmail: String) {
        loginFields.emailAddress = googleEmail
        loginFields.username = googleEmail
        loginFields.meta.socialServiceIDToken = googleToken
        loginFields.meta.googleUser = googleUser
    }

    /// Creates a WordPress.com account with the associated GoogleUser + GoogleToken + GoogleEmail.
    ///
    func createWordPressComUser(googleUser: GIDGoogleUser, googleToken: String, googleEmail: String) {
        SVProgressHUD.show(withStatus: NSLocalizedString("Completing Signup", comment: "Shown while the app waits for the site creation process to complete."))

        let service = SignupService()

        service.createWPComUser(googleToken: googleToken, success: { [weak self] accountCreated, wpcomUsername, wpcomToken in

            let credentials = WordPressCredentials.wpcom(username: wpcomUsername, authToken: wpcomToken, isJetpackLogin: false, multifactor: false)
            self?.authenticationDelegate.sync(credentials: credentials) { _ in
                SVProgressHUD.dismiss()

                if accountCreated {
                    self?.socialSignupWasSuccessful(with: credentials)
                } else {
                    self?.socialLoginWasSuccessful(with: credentials)
                }
            }

        }, failure: { [weak self] error in
            SVProgressHUD.dismiss()
            self?.socialSignupDidFail(with: error)
        })
    }


    /// Social Signup Successful: Analytics + Pushing the Signup Epilogue.
    ///
    func socialSignupWasSuccessful(with credentials: WordPressCredentials) {
        WordPressAuthenticator.track(.createdAccount, properties: ["source": "google"])
        WordPressAuthenticator.track(.signupSocialSuccess)

        showSignupEpilogue(for: credentials)
    }

    /// Social Login Successful: Analytics + Pushing the Login Epilogue.
    ///
    func socialLoginWasSuccessful(with credentials: WordPressCredentials) {
        WordPressAuthenticator.track(.loginSocialSuccess)
        WordPressAuthenticator.track(.signupSocialToLogin)

        showLoginEpilogue(for: credentials)
    }

    /// Social Signup Failure: Analytics + UI Updates
    ///
    func socialSignupDidFail(with error: Error) {
        WPAnalytics.track(.signupSocialFailure)

        titleLabel.textColor = WPStyleGuide.errorRed()
        titleLabel.text = NSLocalizedString("Google sign up failed.", comment: "Message shown on screen after the Google sign up process failed.")
        displayError(error as NSError, sourceTag: .wpComSignup)
    }
}

// MARK: - GIDSignInUIDelegate

/// This is needed to set self as UIDelegate, even though none of the methods are called
extension SignupGoogleViewController: GIDSignInUIDelegate {

}
