import Foundation
import AuthenticationServices
import WordPressKit
import SVProgressHUD
import WordPressShared

@objc protocol AppleAuthenticatorDelegate {
    func showWPComLogin(loginFields: LoginFields)
    func showApple2FA(loginFields: LoginFields)
    func authFailedWithError(message: String)
}

class AppleAuthenticator: NSObject {

    // MARK: - Properties

    static var sharedInstance: AppleAuthenticator = AppleAuthenticator()
    private var showFromViewController: UIViewController?
    private let loginFields = LoginFields()
    weak var delegate: AppleAuthenticatorDelegate?
    let signupService: SocialUserCreating

    init(signupService: SocialUserCreating = SignupService()) {
        self.signupService = signupService
        super.init()
    }

    static let credentialRevokedNotification = ASAuthorizationAppleIDProvider.credentialRevokedNotification

    private var tracker: AuthenticatorAnalyticsTracker {
        AuthenticatorAnalyticsTracker.shared
    }

    private var authenticationDelegate: WordPressAuthenticatorDelegate {
        guard let delegate = WordPressAuthenticator.shared.delegate else {
            fatalError()
        }
        return delegate
    }

    // MARK: - Start Authentication

    func showFrom(viewController: UIViewController) {
        loginFields.meta.socialService = SocialServiceName.apple
        showFromViewController = viewController
        requestAuthorization()
    }
}

// MARK: - Tracking

private extension AppleAuthenticator {
    func track(_ event: WPAnalyticsStat, properties: [AnyHashable: Any] = [:]) {
        var trackProperties = properties
        trackProperties["source"] = "apple"
        WordPressAuthenticator.track(event, properties: trackProperties)
    }
}

// MARK: - Authentication Flow

private extension AppleAuthenticator {

    func requestAuthorization() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self

        controller.presentationContextProvider = self
        controller.performRequests()
    }

    /// Creates a WordPress.com account with the Apple ID
    ///
    func createWordPressComUser(appleCredentials: ASAuthorizationAppleIDCredential) {
        guard let identityToken = appleCredentials.identityToken,
            let token = String(data: identityToken, encoding: .utf8) else {
                WPAuthenticatorLogError("Apple Authenticator: invalid Apple credentials.")
                return
        }

        createWordPressComUser(
            appleUserId: appleCredentials.user,
            email: appleCredentials.email ?? "",
            name: fullName(from: appleCredentials.fullName),
            token: token
        )
    }

    func signupSuccessful(with credentials: AuthenticatorCredentials) {
        // This stat is part of a funnel that provides critical information.  Before
        // making ANY modification to this stat please refer to: p4qSXL-35X-p2
        track(.createdAccount)

        tracker.track(step: .success) {
            track(.signupSocialSuccess)
        }

        showSignupEpilogue(for: credentials)
    }

    func loginSuccessful(with credentials: AuthenticatorCredentials) {
        // This stat is part of a funnel that provides critical information.  Please
        // consult with your lead before removing this event.
        track(.signedIn)

        tracker.track(step: .success) {
            track(.loginSocialSuccess)
        }

        showLoginEpilogue(for: credentials)
    }

    func showLoginEpilogue(for credentials: AuthenticatorCredentials) {
        guard let navigationController = showFromViewController?.navigationController else {
            fatalError()
        }

        authenticationDelegate.presentLoginEpilogue(in: navigationController,
                                                    for: credentials,
                                                    source: WordPressAuthenticator.shared.signInSource) {}
    }

    func signupFailed(with error: Error) {
        WPAuthenticatorLogError("Apple Authenticator: Signup failed. error: \(error.localizedDescription)")

        let errorMessage = error.localizedDescription

        tracker.track(failure: errorMessage) {
            let properties = ["error": errorMessage]
            track(.signupSocialFailure, properties: properties)
        }

        delegate?.authFailedWithError(message: error.localizedDescription)
    }

    func logInInstead() {
        tracker.set(flow: .loginWithApple)
        tracker.track(step: .start) {
            track(.signupSocialToLogin)
            track(.loginSocialSuccess)
        }

        delegate?.showWPComLogin(loginFields: loginFields)
    }

    func show2FA() {
        if tracker.shouldUseLegacyTracker() {
            track(.signupSocialToLogin)
        }

        delegate?.showApple2FA(loginFields: loginFields)
    }

    // MARK: - Helpers

    func fullName(from components: PersonNameComponents?) -> String {
        guard let name = components else {
            return ""
        }
        return PersonNameComponentsFormatter().string(from: name)
    }

    func updateLoginFields(email: String, fullName: String, token: String) {
        updateLoginEmail(email)
        loginFields.meta.socialServiceIDToken = token
        loginFields.meta.socialUser = SocialUser(email: email, fullName: fullName, service: .apple)
    }

    func updateLoginEmail(_ email: String) {
        loginFields.emailAddress = email
        loginFields.username = email
    }

}

extension AppleAuthenticator: ASAuthorizationControllerDelegate {

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let credentials as ASAuthorizationAppleIDCredential:
            createWordPressComUser(appleCredentials: credentials)
        default:
            break
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {

        // Don't show error if user cancelled authentication.
        if let authorizationError = error as? ASAuthorizationError,
            authorizationError.code == .canceled {
            return
        }

        WPAuthenticatorLogError("Apple Authenticator: didCompleteWithError: \(error.localizedDescription)")
        let message = NSLocalizedString("Apple authentication failed.\nPlease make sure you are signed in to iCloud with an Apple ID that uses two-factor authentication.", comment: "Message shown when Apple authentication fails.")
        delegate?.authFailedWithError(message: message)
    }
}

extension AppleAuthenticator: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return showFromViewController?.view.window ?? UIWindow()
    }
}

extension AppleAuthenticator {
    func getAppleIDCredentialState(for userID: String,
                                   completion: @escaping (ASAuthorizationAppleIDProvider.CredentialState, Error?) -> Void) {
        ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID, completion: completion)
    }
}

// This needs to be internal, at this point in time, to allow testing.
//
// Notice that none of this code was previously tested. A small encapsulation breach like this is
// worth the testability we gain from it.
extension AppleAuthenticator {

    func showSignupEpilogue(for credentials: AuthenticatorCredentials) {
        guard let navigationController = showFromViewController?.navigationController else {
            fatalError()
        }

        authenticationDelegate.presentSignupEpilogue(
            in: navigationController,
            for: credentials,
            socialUser: loginFields.meta.socialUser
        )
    }

    func createWordPressComUser(appleUserId: String, email: String, name: String, token: String) {
        tracker.set(flow: .signupWithApple)
        tracker.track(step: .start) {
            track(.createAccountInitiated)
        }

        SVProgressHUD.show(
            withStatus: NSLocalizedString(
                "Continuing with Apple",
                comment: "Shown while logging in with Apple and the app waits for the site creation process to complete."
            )
        )

        updateLoginFields(email: email, fullName: name, token: token)

        signupService.createWPComUserWithApple(
            token: token,
            email: email,
            fullName: name,
            success: { [weak self] accountCreated, existingNonSocialAccount, existing2faAccount, wpcomUsername, wpcomToken in
                SVProgressHUD.dismiss()

                // Notify host app of successful Apple authentication
                self?.authenticationDelegate.userAuthenticatedWithAppleUserID(appleUserId)

                guard !existingNonSocialAccount else {
                    self?.tracker.set(flow: .loginWithApple)

                    if existing2faAccount {
                        self?.show2FA()
                        return
                    }

                    self?.updateLoginEmail(wpcomUsername)
                    self?.logInInstead()
                    return
                }

                let wpcom = WordPressComCredentials(authToken: wpcomToken, isJetpackLogin: false, multifactor: false, siteURL: self?.loginFields.siteAddress ?? "")
                let credentials = AuthenticatorCredentials(wpcom: wpcom)

                if accountCreated {
                    self?.authenticationDelegate.createdWordPressComAccount(username: wpcomUsername, authToken: wpcomToken)
                    self?.signupSuccessful(with: credentials)
                } else {
                    self?.authenticationDelegate.sync(credentials: credentials) {
                        self?.loginSuccessful(with: credentials)
                    }
                }

            },
            failure: { [weak self] error in
                SVProgressHUD.dismiss()
                self?.signupFailed(with: error)
            }
        )
    }
}
