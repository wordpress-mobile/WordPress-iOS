import UIKit
import WordPressShared

/// View controller that handles the google signup flow
///
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
        titleLabel?.text = LocalizedText.waitingForGoogle
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showGoogleScreenIfNeeded()
    }

}

// MARK: - Private Methods

private extension SignupGoogleViewController {

    func showGoogleScreenIfNeeded() {
        guard !hasShownGoogle else {
            return
        }

        // Flag this as a social sign in.
        loginFields.meta.socialService = .google

        GoogleAuthenticator.sharedInstance.signupDelegate = self
        GoogleAuthenticator.sharedInstance.showFrom(viewController: self, loginFields: loginFields, for: .signup)

        hasShownGoogle = true
    }

    enum LocalizedText {
        static let waitingForGoogle = NSLocalizedString("Waiting for Google to complete…", comment: "Message shown on screen while waiting for Google to finish its signup process.")
        static let signupFailed = NSLocalizedString("Google sign up failed.", comment: "Message shown on screen after the Google sign up process failed.")
    }

}

// MARK: - GoogleAuthenticatorSignupDelegate

extension SignupGoogleViewController: GoogleAuthenticatorSignupDelegate {

    func googleFinishedSignup(credentials: AuthenticatorCredentials, loginFields: LoginFields) {
        self.loginFields = loginFields
        showSignupEpilogue(for: credentials)
    }

    func googleLoggedInInstead(credentials: AuthenticatorCredentials, loginFields: LoginFields) {
        self.loginFields = loginFields
        showLoginEpilogue(for: credentials)
    }

    func googleSignupFailed(error: Error, loginFields: LoginFields) {
        self.loginFields = loginFields
        titleLabel?.textColor = .systemRed
        titleLabel?.text = LocalizedText.signupFailed
        displayError(error, sourceTag: .wpComSignup)
    }

    func googleSignupCancelled() {
        navigationController?.popViewController(animated: true)
    }

}
