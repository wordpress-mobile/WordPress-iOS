import Foundation
import AuthenticationServices
import SVProgressHUD
import WordPressKit

/// The authorization flow handled by this class starts by showing Apple's `ASAuthorizationController`
/// through our class `StoredCredentialsPicker`.  This controller lets the user pick the credentials they
/// want to login with.  This class handles both showing that controller and executing the remaining flow to
/// complete the login process.
///
class StoredCredentialsAuthenticator: NSObject {

    // MARK: - Delegates

    private var authenticationDelegate: WordPressAuthenticatorDelegate {
        guard let delegate = WordPressAuthenticator.shared.delegate else {
            fatalError()
        }
        return delegate
    }

    // MARK: - Configuration

    private var authConfig: WordPressAuthenticatorConfiguration {
        WordPressAuthenticator.shared.configuration
    }

    // MARK: - Login Support

    private lazy var loginFacade: LoginFacade = {
        let facade = LoginFacade(dotcomClientID: authConfig.wpcomClientId,
                                 dotcomSecret: authConfig.wpcomSecret,
                                 userAgent: authConfig.userAgent)
        facade.delegate = self
        return facade
    }()

    // MARK: - Cancellation

    private let onCancel: (() -> Void)?

    // MARK: - UI

    private let picker = StoredCredentialsPicker()
    private weak var navigationController: UINavigationController?

    // MARK: - Tracking Support

    private var tracker: AuthenticatorAnalyticsTracker {
        AuthenticatorAnalyticsTracker.shared
    }

    // MARK: - Login Fields

    private var loginFields: LoginFields?

    // MARK: - Initialization

    init(onCancel: (() -> Void)? = nil) {
        self.onCancel = onCancel
    }

    // MARK: - Picker

    /// Shows the UI for picking stored credentials for the user to log into their account.
    ///
    func showPicker(from navigationController: UINavigationController) {
        self.navigationController = navigationController

        guard let window = navigationController.view.window else {
            WPAuthenticatorLogError("Can't obtain window for navigation controller")
            return
        }

        picker.show(in: window) { [weak self] result in
            guard let self else {
                return
            }

            switch result {
            case .success(let authorization):
                self.pickerSuccess(authorization)
            case .failure(let error):
                self.pickerFailure(error)
            }
        }
    }

    /// The selection of credentials and subsequent authorization by the OS succeeded.  This method processes the credentials
    /// and proceeds with the login operation.
    ///
    /// - Parameters:
    ///         - authorization: The authorization by the OS, containing the credentials picked by the user.
    ///
    private func pickerSuccess(_ authorization: ASAuthorization) {
        tracker.track(step: .start)
        tracker.set(flow: .loginWithiCloudKeychain)
        SVProgressHUD.show()

        switch authorization.credential {
        case _ as ASAuthorizationAppleIDCredential:
            // No-op for now, but we can decide to implement AppleID login through this authenticator
            // by implementing the logic here.
            break
        case let credential as ASPasswordCredential:
            let loginFields = LoginFields.makeForWPCom(username: credential.user, password: credential.password)
            loginFacade.signIn(with: loginFields)
            self.loginFields = loginFields
        default:
            // There aren't any other known methods for us to handle here, but we still need to complete the switch
            // statement.
            break
        }
    }

    /// The selection of credentials or the subsequent authorization by the OS failed.  This method processes the failure.
    ///
    /// - Parameters:
    ///         - error: The error detailing what failed.
    ///
    private func pickerFailure(_ error: Error) {
        let authError = ASAuthorizationError(_nsError: error as NSError)

        switch authError.code {
        case .canceled:
            // The user cancelling the flow is not really an error, so we're not reporting or tracking
            // this as an error.
            //
            // We're not tracking this either, since the Android App doesn't for SmartLock.  The reason is
            // that it's not trivial to know when the credentials picker UI is shown to the user, so knowing
            // it's being dismissed is also not trivial.  This was decided during the Unified Login & Signup
            // project in a conversation between myself (Diego Rey Mendez) and Renan Ferrari.
            break
        default:
            tracker.track(failure: authError.localizedDescription)
            WPAuthenticatorLogError("ASAuthorizationError: \(authError.localizedDescription)")
        }
    }
}

extension StoredCredentialsAuthenticator: LoginFacadeDelegate {
    func displayRemoteError(_ error: Error) {
        tracker.track(failure: error.localizedDescription)
        SVProgressHUD.dismiss()

        guard authConfig.enableUnifiedAuth else {
            presentLoginEmailView(error: error)
            return
        }

        presentGetStartedView(error: error)
    }

    func needsMultifactorCode() {
        SVProgressHUD.dismiss()
        presentTwoFactorAuthenticationView()
    }

    func needsMultifactorCode(forUserID userID: Int, andNonceInfo nonceInfo: SocialLogin2FANonceInfo) {
        loginFields?.nonceInfo = nonceInfo
        loginFields?.nonceUserID = userID

        needsMultifactorCode()
    }

    func finishedLogin(withAuthToken authToken: String, requiredMultifactorCode: Bool) {
        let wpcom = WordPressComCredentials(
            authToken: authToken,
            isJetpackLogin: false,
            multifactor: requiredMultifactorCode,
            siteURL: "")
        let credentials = AuthenticatorCredentials(wpcom: wpcom)

        authenticationDelegate.sync(credentials: credentials) { [weak self] in
            SVProgressHUD.dismiss()
            self?.presentLoginEpilogue(credentials: credentials)
        }
    }
}

// MARK: - UI Flow

extension StoredCredentialsAuthenticator {
    private func presentLoginEpilogue(credentials: AuthenticatorCredentials) {
        guard let navigationController = self.navigationController else {
            WPAuthenticatorLogError("No navigation controller to present the login epilogue from")
            return
        }

        authenticationDelegate.presentLoginEpilogue(in: navigationController,
                                                    for: credentials,
                                                    source: WordPressAuthenticator.shared.signInSource,
                                                    onDismiss: {})
    }

    /// Presents the login email screen, displaying the specified error.  This is useful
    /// for example for iCloud Keychain in the case where there's an error logging the user
    /// in with the stored credentials for whatever reason.
    ///
    private func presentLoginEmailView(error: Error) {
        guard let toVC = LoginEmailViewController.instantiate(from: .login) else {
            WPAuthenticatorLogError("Failed to navigate to LoginEmailVC from LoginPrologueVC")
            return
        }

        if let loginFields {
            toVC.loginFields = loginFields
        }
        toVC.errorToPresent = error

        navigationController?.pushViewController(toVC, animated: true)
    }

    /// Presents the get started screen, displaying the specified error.  This is useful
    /// for example for iCloud Keychain in the case where there's an error logging the user
    /// in with the stored credentials for whatever reason.
    ///
    private func presentGetStartedView(error: Error) {
        guard let toVC = GetStartedViewController.instantiate(from: .getStarted) else {
            WPAuthenticatorLogError("Failed to navigate to GetStartedViewController")
            return
        }

        if let loginFields {
            toVC.loginFields = loginFields
        }

        toVC.errorMessage = error.localizedDescription
        navigationController?.pushViewController(toVC, animated: true)
    }

    private func presentTwoFactorAuthenticationView() {
        guard let loginFields else {
            return
        }

        guard let vc = TwoFAViewController.instantiate(from: .twoFA) else {
            WPAuthenticatorLogError("Failed to navigate from LoginViewController to TwoFAViewController")
            return
        }

        vc.loginFields = loginFields

        navigationController?.pushViewController(vc, animated: true)
    }
}
