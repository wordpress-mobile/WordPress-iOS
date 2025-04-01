import Foundation
import SVProgressHUD
import WordPressKit
import WordPressShared

/// Contains delegate methods for Google authentication unified auth flow.
/// Both Login and Signup are handled via this delegate.
///
protocol GoogleAuthenticatorDelegate: AnyObject {
    // Google account login was successful.
    func googleFinishedLogin(credentials: AuthenticatorCredentials, loginFields: LoginFields)

    // Google account login was successful, but a WP 2FA code is required.
    func googleNeedsMultifactorCode(loginFields: LoginFields)

    // Google account login was successful, but a WP password is required.
    func googleExistingUserNeedsConnection(loginFields: LoginFields)

    // Google account login failed.
    func googleLoginFailed(errorTitle: String, errorDescription: String, loginFields: LoginFields, unknownUser: Bool)

    // Google account selection cancelled by user.
    func googleAuthCancelled()

    // Google account signup was successful.
    func googleFinishedSignup(credentials: AuthenticatorCredentials, loginFields: LoginFields)

    // Google account signup redirected to login was successful.
    func googleLoggedInInstead(credentials: AuthenticatorCredentials, loginFields: LoginFields)

    // Google account signup failed.
    func googleSignupFailed(error: Error, loginFields: LoginFields)
}

/// Indicate which type of authentication is initiated.
/// Utilized by ViewControllers that handle separate Google Login and Signup flows.
/// This is needed as long as:
///     Separate Google Login and Signup flows are utilized.
///     Tracking is specific to separate Login and Signup flows.
/// When separate Google Login and Signup flows are no longer used, this no longer needed.
///
enum GoogleAuthType {
    case login
    case signup
}

/// Contains delegate methods for Google login specific flow.
/// When separate Google Login and Signup flows are no longer used, this no longer needed.
///
protocol GoogleAuthenticatorLoginDelegate: AnyObject {
    // Google account login was successful.
    func googleFinishedLogin(credentials: AuthenticatorCredentials, loginFields: LoginFields)

    // Google account login was successful, but a WP 2FA code is required.
    func googleNeedsMultifactorCode(loginFields: LoginFields)

    // Google account login was successful, but a WP password is required.
    func googleExistingUserNeedsConnection(loginFields: LoginFields)

    // Google account login failed.
    func googleLoginFailed(errorTitle: String, errorDescription: String, loginFields: LoginFields)
}

/// Contains delegate methods for Google signup specific flow.
/// When separate Google Login and Signup flows are no longer used, this no longer needed.
///
protocol GoogleAuthenticatorSignupDelegate: AnyObject {
    // Google account signup was successful.
    func googleFinishedSignup(credentials: AuthenticatorCredentials, loginFields: LoginFields)

    // Google account signup redirected to login was successful.
    func googleLoggedInInstead(credentials: AuthenticatorCredentials, loginFields: LoginFields)

    // Google account signup failed.
    func googleSignupFailed(error: Error, loginFields: LoginFields)

    // Google account signup cancelled by user.
    func googleSignupCancelled()
}

class GoogleAuthenticator: NSObject {

    // MARK: - Properties

    static var sharedInstance: GoogleAuthenticator = GoogleAuthenticator()
    weak var loginDelegate: GoogleAuthenticatorLoginDelegate?
    weak var signupDelegate: GoogleAuthenticatorSignupDelegate?
    weak var delegate: GoogleAuthenticatorDelegate?

    private var loginFields = LoginFields()
    private let authConfig = WordPressAuthenticator.shared.configuration
    private var authType: GoogleAuthType = .login

    private var tracker: AuthenticatorAnalyticsTracker {
        AuthenticatorAnalyticsTracker.shared
    }

    private lazy var loginFacade: LoginFacade = {
        let facade = LoginFacade(dotcomClientID: authConfig.wpcomClientId,
                                 dotcomSecret: authConfig.wpcomSecret,
                                 userAgent: authConfig.userAgent)
        facade.delegate = self
        return facade
    }()

    private weak var authenticationDelegate: WordPressAuthenticatorDelegate? = {
        guard let delegate = WordPressAuthenticator.shared.delegate else {
            fatalError()
        }
        return delegate
    }()

    // MARK: - Start Authentication

    /// Public method to initiate the Google auth process.
    /// - Parameters:
    ///   - viewController: The UIViewController that Google is being presented from.
    ///                     Required by Google SDK.
    ///   - loginFields: LoginFields from the calling view controller.
    ///                  The values are updated during the Google process,
    ///                  and returned to the calling view controller via delegate methods.
    ///   - authType: Indicates the type of authentication (login or signup)
    func showFrom(
        viewController: UIViewController,
        loginFields: LoginFields,
        for authType: GoogleAuthType = .login
    ) {
        // The fact that we set `loginFields`, then reset its `meta.socialService` property doesn't
        // seem ideal...
        self.loginFields = loginFields
        self.loginFields.meta.socialService = SocialServiceName.google
        self.authType = authType

        Task { @MainActor in
            do {
                let token = try await requestAuthorization(
                    for: authType,
                    from: viewController,
                    loginFields: loginFields
                )

                didSignIn(token: token.token.rawValue, email: token.email, fullName: token.name)
            } catch {
                failedToSignIn(error: error)
            }
        }
    }

    /// Public method to create a WP account with a Google account.
    /// - Parameters:
    ///   - loginFields: LoginFields from the calling view controller.
    ///                  The values are updated during the Google process,
    ///                  and returned to the calling view controller via delegate methods.
    func createGoogleAccount(loginFields: LoginFields) {
        self.loginFields = loginFields

        guard let token = loginFields.meta.socialServiceIDToken else {
            WPAuthenticatorLogError("GoogleAuthenticator - createGoogleAccount: Failed to get Google account information.")
            return
        }

        createWordPressComUser(token: token, email: loginFields.emailAddress)
    }

}

// MARK: - Private Extension

private extension GoogleAuthenticator {

    private func trackRequestAuthorizitation(type: GoogleAuthType) {
        switch type {
        case .login:
            tracker.set(flow: .loginWithGoogle)
            tracker.track(step: .start) {
                track(.loginSocialButtonClick)
            }
        case .signup:
            track(.createAccountInitiated)
        }
    }

    func track(_ event: WPAnalyticsStat, properties: [AnyHashable: Any] = [:]) {
        var trackProperties = properties
        trackProperties["source"] = "google"
        WordPressAuthenticator.track(event, properties: trackProperties)
    }

    private func failedToSignIn(error: Error?) {
        // The Google SignIn may have been cancelled.
        //
        // FIXME: Is `error == .none` how we distinguish between user cancellation and legit error?
        let failure = error?.localizedDescription ?? "Unknown error"

        tracker.track(failure: failure, ifTrackingNotEnabled: {
            let properties = ["error": failure]

            switch authType {
            case .login:
                track(.loginSocialButtonFailure, properties: properties)
            case .signup:
                track(.signupSocialButtonFailure, properties: properties)
            }
        })

        // Notify the delegates so the Google Auth view can be dismissed.
        //
        // FIXME: Shouldn't we be calling a method to report error, if there was one?
        signupDelegate?.googleSignupCancelled()
        delegate?.googleAuthCancelled()
    }

    private func didSignIn(token: String, email: String, fullName: String) {
        // Save account information to pass back to delegate later.
        loginFields.emailAddress = email
        loginFields.username = email
        loginFields.meta.socialServiceIDToken = token
        loginFields.meta.socialUser = SocialUser(email: email, fullName: fullName, service: .google)

        guard authConfig.enableUnifiedAuth else {
            // Initiate separate WP login / signup paths.
            switch authType {
            case .login:
                SVProgressHUD.show()
                loginFacade.loginToWordPressDotCom(withSocialIDToken: token, service: SocialServiceName.google.rawValue)
            case .signup:
                createWordPressComUser(token: token, email: email)
            }

            return
        }

        // Initiate unified path by attempting to login first.
        //
        // `SVProgressHUD.show()` will crash in an app that doesn't have a window property in its
        // `UIApplicationDelegate`, such as those created via the Xcode templates circa version 12
        // onwards.
        SVProgressHUD.show()
        loginFacade.loginToWordPressDotCom(withSocialIDToken: token, service: SocialServiceName.google.rawValue)
    }

    enum LocalizedText {
        static let googleConnected = NSLocalizedString("Connected But…", comment: "Title shown when a user logs in with Google but no matching WordPress.com account is found")
        static let googleConnectedError = NSLocalizedString("The Google account \"%@\" doesn't match any account on WordPress.com", comment: "Description shown when a user logs in with Google but no matching WordPress.com account is found")
        static let googleUnableToConnect = NSLocalizedString("Unable To Connect", comment: "Shown when a user logs in with Google but it subsequently fails to work as login to WordPress.com")
    }

}

// MARK: - SDK-less flow

extension GoogleAuthenticator {

    private func requestAuthorization(
        for authType: GoogleAuthType,
        from viewController: UIViewController,
        loginFields: LoginFields
    ) async throws -> IDToken {
        // Intentionally duplicated from the callsite, so we don't forget about this when removing
        // the SDK.
        //
        // The fact that we set `loginFields`, then reset its `meta.socialService` property doesn't
        // seem ideal...
        self.loginFields = loginFields
        self.loginFields.meta.socialService = SocialServiceName.google
        self.authType = authType

        trackRequestAuthorizitation(type: authType)

        let sdkLessGoogleAuthenticator = NewGoogleAuthenticator(
            clientId: authConfig.googleClientId,
            scheme: authConfig.googleLoginScheme,
            audience: authConfig.googleLoginServerClientId,
            urlSession: .shared
        )

        await SVProgressHUD.show()
        return try await sdkLessGoogleAuthenticator.getOAuthToken(from: viewController)
    }
}

// MARK: - LoginFacadeDelegate

extension GoogleAuthenticator: LoginFacadeDelegate {

    // Google account login was successful.
    func finishedLogin(withGoogleIDToken googleIDToken: String, authToken: String) {
        SVProgressHUD.dismiss()

        // This stat is part of a funnel that provides critical information.  Please
        // consult with your lead before removing this event.
        track(.signedIn)

        if tracker.shouldUseLegacyTracker() {
            track(.loginSocialSuccess)
        }

        let wpcom = WordPressComCredentials(authToken: authToken,
                                            isJetpackLogin: loginFields.meta.jetpackLogin,
                                            multifactor: false,
                                            siteURL: loginFields.siteAddress)
        let credentials = AuthenticatorCredentials(wpcom: wpcom)

        loginDelegate?.googleFinishedLogin(credentials: credentials, loginFields: loginFields)
        delegate?.googleFinishedLogin(credentials: credentials, loginFields: loginFields)
    }

    // Google account login was successful, but a WP 2FA code is required.
    func needsMultifactorCode(forUserID userID: Int, andNonceInfo nonceInfo: SocialLogin2FANonceInfo) {
        SVProgressHUD.dismiss()

        loginFields.nonceInfo = nonceInfo
        loginFields.nonceUserID = userID

        if tracker.shouldUseLegacyTracker() {
            track(.loginSocial2faNeeded)
        }

        loginDelegate?.googleNeedsMultifactorCode(loginFields: loginFields)
        delegate?.googleNeedsMultifactorCode(loginFields: loginFields)
    }

    // Google account login was successful, but a WP password is required.
    func existingUserNeedsConnection(_ email: String) {
        SVProgressHUD.dismiss()

        loginFields.username = email
        loginFields.emailAddress = email

        if tracker.shouldUseLegacyTracker() {
            track(.loginSocialAccountsNeedConnecting)
        }

        loginDelegate?.googleExistingUserNeedsConnection(loginFields: loginFields)
        delegate?.googleExistingUserNeedsConnection(loginFields: loginFields)
    }

    // Google account login failed.
    func displayRemoteError(_ error: Error) {
        SVProgressHUD.dismiss()

        var errorTitle = LocalizedText.googleUnableToConnect
        var errorDescription = error.localizedDescription
        let unknownUser = (error as? WordPressComOAuthError)?.authenticationFailureKind == .unknownUser

        if unknownUser {
            errorTitle = LocalizedText.googleConnected
            errorDescription = String(format: LocalizedText.googleConnectedError, loginFields.username)

            if tracker.shouldUseLegacyTracker() {
                track(.loginSocialErrorUnknownUser)
            }
        } else {
            // Don't track unknown user for unified Auth.
            tracker.track(failure: errorDescription)
        }

        loginDelegate?.googleLoginFailed(errorTitle: errorTitle, errorDescription: errorDescription, loginFields: loginFields)
        delegate?.googleLoginFailed(errorTitle: errorTitle, errorDescription: errorDescription, loginFields: loginFields, unknownUser: unknownUser)
    }

}

// MARK: - Sign Up Methods

private extension GoogleAuthenticator {

    /// Creates a WordPress.com account with the associated Google token and email.
    ///
    func createWordPressComUser(token: String, email: String) {
        SVProgressHUD.show()
        let service = SignupService()

        service.createWPComUserWithGoogle(token: token, success: { [weak self] accountCreated, wpcomUsername, wpcomToken in

            let wpcom = WordPressComCredentials(authToken: wpcomToken, isJetpackLogin: false, multifactor: false, siteURL: self?.loginFields.siteAddress ?? "")
            let credentials = AuthenticatorCredentials(wpcom: wpcom)

            // New Account
            if accountCreated {
                SVProgressHUD.dismiss()
                // Notify the host app
                self?.authenticationDelegate?.createdWordPressComAccount(username: wpcomUsername, authToken: wpcomToken)
                // Notify the delegate
                self?.accountCreated(credentials: credentials)

                return
            }

            // Existing Account
            // Sync host app
            self?.authenticationDelegate?.sync(credentials: credentials) {
                SVProgressHUD.dismiss()
                // Notify delegate
                self?.logInInstead(credentials: credentials)
            }

            }, failure: { [weak self] error in
                SVProgressHUD.dismiss()
                // Notify delegate
                self?.signupFailed(error: error)
        })
    }

    func accountCreated(credentials: AuthenticatorCredentials) {
        // This stat is part of a funnel that provides critical information.  Before
        // making ANY modification to this stat please refer to: p4qSXL-35X-p2
        track(.createdAccount)

        // This stat is part of a funnel that provides critical information.  Please
        // consult with your lead before removing this event.
        track(.signedIn)

        tracker.track(step: .success, ifTrackingNotEnabled: {
            track(.signupSocialSuccess)
        })

        signupDelegate?.googleFinishedSignup(credentials: credentials, loginFields: loginFields)
        delegate?.googleFinishedSignup(credentials: credentials, loginFields: loginFields)
    }

    func logInInstead(credentials: AuthenticatorCredentials) {
        tracker.set(flow: .loginWithGoogle)

        // This stat is part of a funnel that provides critical information.  Please
        // consult with your lead before removing this event.
        track(.signedIn)

        tracker.track(step: .start) {
            track(.signupSocialToLogin)
            track(.loginSocialSuccess)
        }

        signupDelegate?.googleLoggedInInstead(credentials: credentials, loginFields: loginFields)
        delegate?.googleLoggedInInstead(credentials: credentials, loginFields: loginFields)
    }

    func signupFailed(error: Error) {
        tracker.track(failure: error.localizedDescription, ifTrackingNotEnabled: {
            track(.signupSocialFailure, properties: ["error": error.localizedDescription])
        })

        signupDelegate?.googleSignupFailed(error: error, loginFields: loginFields)
        delegate?.googleSignupFailed(error: error, loginFields: loginFields)
    }

}
