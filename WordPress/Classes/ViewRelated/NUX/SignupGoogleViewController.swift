import GoogleSignIn

/// View controller that handles the google signup code
class SignupGoogleViewController: LoginViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        showGoogleScreen()
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

        WPAppAnalytics.track(.loginSocialButtonClick)
    }
}

extension SignupGoogleViewController: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn?, didSignInFor user: GIDGoogleUser?, withError error: Error?) {
        guard let user = user,
            let token = user.authentication.idToken,
            let email = user.profile.email else {
                // The Google SignIn for may have been canceled.
//                if let err = error {
//                    WPAppAnalytics.track(.loginSocialButtonFailure, error: err)
//                } else {
//                    WPAppAnalytics.track(.loginSocialButtonFailure)
//                }
                self.navigationController?.popViewController(animated: true)
                return
        }
        NSLog(token)

        // Store the email address and token.
        loginFields.emailAddress = email
        loginFields.username = email
        loginFields.meta.socialServiceIDToken = token

        let context = ContextManager.sharedInstance().mainContext
        let service = SignupService(managedObjectContext: context)
        service.createWPComeUserWithGoogle(token: token, success: { [weak self] in
            
            self?.performSegue(withIdentifier: .showEpilogue, sender: self)
        }) { [weak self] (error) in
            guard let error = error else {
                self?.navigationController?.popViewController(animated: true)
                return
            }
            self?.displayError(error as NSError, sourceTag: .wpComSignup)
        }
    }
}

extension SignupGoogleViewController: GIDSignInUIDelegate {
}
