import GoogleSignIn
import SVProgressHUD

/// View controller that handles the google signup code
class SignupGoogleViewController: LoginViewController {

    // MARK: - Properties

    private var hasShownGoogle = false
    @IBOutlet var titleLabel: UILabel?

    override var sourceTag: WordPressSupportSourceTag {
        get {
            return .wpComSignupWaitingForGoogle
        }
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel?.text = NSLocalizedString("Waiting for Google to complete…", comment: "Message shown on screen while waiting for Google to finish its signup process.")
        WordPressAuthenticator.post(event: .createAccountInitiated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !hasShownGoogle {
            showGoogleScreen()
            hasShownGoogle = true
        }
    }

    private func showGoogleScreen() {
        GIDSignIn.sharedInstance().disconnect()

        // Flag this as a social sign in.
        loginFields.meta.socialService = SocialServiceName.google

        // Configure all the things and sign in.
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().clientID = ApiCredentials.googleLoginClientId()
        GIDSignIn.sharedInstance().serverClientID = ApiCredentials.googleLoginServerClientId()

        GIDSignIn.sharedInstance().signIn()

        WordPressAuthenticator.post(event: .loginSocialButtonClick)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let vc = segue.destination as? SignupEpilogueViewController {
            vc.loginFields = loginFields
        }
    }

}

// MARK: - GIDSignInDelegate

extension SignupGoogleViewController: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn?, didSignInFor user: GIDGoogleUser?, withError error: Error?) {
        GIDSignIn.sharedInstance().disconnect()

        guard let user = user,
            let token = user.authentication.idToken,
            let email = user.profile.email else {
                self.navigationController?.popViewController(animated: true)
                return
        }

        // Store the email address and token.
        loginFields.emailAddress = email
        loginFields.username = email
        loginFields.meta.socialServiceIDToken = token
        loginFields.meta.googleUser = user

        SVProgressHUD.show(withStatus: NSLocalizedString("Completing Signup", comment: "Shown while the app waits for the site creation process to complete."))

        let context = ContextManager.sharedInstance().mainContext
        let service = SignupService(managedObjectContext: context)
        let credentials = WordPressCredentials.wpcom(username: email, authToken: token, isJetpackLogin: isJetpackLogin, multifactor: false)

        service.createWPComUserWithGoogle(token: token, success: { [weak self] (accountCreated) in
            SVProgressHUD.dismiss()
            if accountCreated {
                self?.performSegue(withIdentifier: .showSignupEpilogue, sender: self)
                WordPressAuthenticator.post(event: .signupSocialSuccess)
            } else {
                self?.showLoginEpilogue(for: credentials)
                WordPressAuthenticator.post(event: .loginSocialSuccess)
            }
        }) { [weak self] (error) in
            SVProgressHUD.dismiss()
            WPAnalytics.track(.signupSocialFailure)
            guard let error = error else {
                self?.navigationController?.popViewController(animated: true)
                return
            }
            self?.titleLabel?.textColor = WPStyleGuide.errorRed()
            self?.titleLabel?.text = NSLocalizedString("Google sign up failed.",
                                                       comment: "Message shown on screen after the Google sign up process failed.")
            self?.displayError(error as NSError, sourceTag: .wpComSignup)
        }
    }
}

// MARK: - GIDSignInUIDelegate

/// This is needed to set self as uiDelegate, even though none of the methods are called
extension SignupGoogleViewController: GIDSignInUIDelegate {
}
