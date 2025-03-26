import Alamofire
import AuthenticationServices
import Foundation
import UIKit
import WordPressData
import WordPressShared

/// Log in or sign up a WordPress.com account via web.
///
/// API doc: https://developer.wordpress.com/docs/oauth2/
struct WordPressDotComAuthenticator {
    enum SignInContext {
        // Sign in to the app with a WordPress.com account.
        // Using this context results in automatically reloading the app to display an site in the account.
        case `default`
        // Sign in to an existing account.
        // This is typically used when the app needs to get a new OAuth token because the current one becomes invalid.
        case reauthentication(accountEmail: String?)
        // Connect a site to Jetpack or sign in to an already connected site.
        case jetpackSite(accountEmail: String?)

        func accountEmail(in context: NSManagedObjectContext) -> String? {
            switch self {
            case .default:
                return nil
            case let .reauthentication(email), let .jetpackSite(email):
                return email
            }
        }
    }

    enum AuthenticationError: Error {
        case invalidCallbackURL
        case loginDenied(message: String)
        case loginAgainRejected
        case obtainAccessToken
        case urlError(URLError)
        case parsing(DecodingError)
        case cancelled
        case unknown(Error)
    }

    enum SignInError: Error {
        case authentication(AuthenticationError)
        case fetchUser(Error)
        case mismatchedEmail(expectedEmail: String)
        case alreadySignedIn(signedInAccountEmail: String)
        case loadingSites(Error)
    }

    private let coreDataStack: CoreDataStackSwift
    private let authenticator: ((URL) throws(AuthenticationError) -> URL)?

    init(
        coreDataStack: CoreDataStackSwift = ContextManager.shared,
        authenticator: ((URL) throws(AuthenticationError) -> URL)? = nil
    ) {
        self.coreDataStack = coreDataStack
        self.authenticator = authenticator
    }

    /// Sign in WP.com account.
    ///
    /// - Parameters:
    ///   - email: When provided, the signed-in account must be the account with the given email address.
    @MainActor
    func signIn(from viewController: UIViewController, context: SignInContext) async -> TaggedManagedObjectID<WPAccount>? {
        WPAnalytics.track(.wpcomWebSignIn, properties: ["stage": "start"])
        do {
            let account = try await attemptSignIn(from: viewController, context: context)
            WPAnalytics.track(.wpcomWebSignIn, properties: ["stage": "success"])
            return account
        } catch {
            present(error, from: viewController)
            WPAnalytics.track(.wpcomWebSignIn, properties: ["stage": "error", "error": "\(error)"])
            return nil
        }
    }

    /// Sign in WP.com account.
    ///
    /// - SeeAlso: `signIn`
    ///
    /// - Parameters:
    ///   - email: When provided, the signed-in account must be the account with the given email address.
    @MainActor
    func attemptSignIn(from viewController: UIViewController, context: SignInContext) async throws(SignInError) -> TaggedManagedObjectID<WPAccount> {
        let defaultAccount = try? WPAccount.lookupDefaultWordPressComAccount(in: coreDataStack.mainContext)
        let hasAlreadySignedIn = defaultAccount != nil

        let token: String
        do {
            token = try await authenticate(from: viewController, prefersEphemeralWebBrowserSession: hasAlreadySignedIn, accountEmail: context.accountEmail(in: coreDataStack.mainContext))
        } catch {
            throw .authentication(error)
        }

        SVProgressHUD.show()
        defer {
            SVProgressHUD.dismiss()
        }

        // Fetch WP.com account details
        let user: RemoteUser
        do {
            let service = AccountServiceRemoteREST(wordPressComRestApi: .defaultApi(oAuthToken: token, userAgent: WPUserAgent.wordPress()))
            user = try await withCheckedThrowingContinuation { continuation in
                service.getAccountDetails(success: { continuation.resume(returning: $0!) }, failure: { continuation.resume(throwing: $0!) })
            }
        } catch {
            throw .fetchUser(error)
        }

        // Make sure the signed-in account matches the given `accountEmail` argument.
        if let email = context.accountEmail(in: coreDataStack.mainContext), user.email != email {
            throw .mismatchedEmail(expectedEmail: email)
        }

        if let defaultAccountEmail = defaultAccount?.email, defaultAccountEmail != user.email {
            throw .alreadySignedIn(signedInAccountEmail: defaultAccountEmail)
        }

        // Save the signed-in account details (and sites) into Core Data.
        let accountID: TaggedManagedObjectID<WPAccount>
        do {
            let isJetpackLogin: Bool
            if case .jetpackSite = context {
                isJetpackLogin = true
            } else {
                isJetpackLogin = false
            }

            let service = WordPressComSyncService(coreDataStack: coreDataStack)
            accountID = try await service.syncWPCom(remoteUser: user, authToken: token, isJetpackLogin: isJetpackLogin)
        } catch {
            DDLogError("Failed to syncing WP.com account: \(error)")
            throw .loadingSites(error)
        }

        // Post a notification if the current signed-in account is set as the default account.
        // This sending notification code exists because that's what the existing login system does. We can consider
        // removing this notification once WordPressAuthenticator is removed.
        if case .default = context {
            let notification = Foundation.Notification.Name(rawValue: WordPressAuthenticationManager.WPSigninDidFinishNotification)
            let newAccount = try? coreDataStack.mainContext.existingObject(with: accountID)
            NotificationCenter.default.post(name: notification, object: newAccount)
        }

        return accountID
    }

    func present(_ error: SignInError, from viewController: UIViewController) {
        guard let alertMessage = error.alertMessage else { return }

        let alert = UIAlertController(
            title: NSLocalizedString("generic.error.title", value: "Error", comment: "A generic title for an error"),
            message: alertMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: SharedStrings.Button.close, style: .cancel, handler: nil))
        viewController.present(alert, animated: true)
    }

    /// Get an OAuth access token from WP.com authentication.
    ///
    /// This method does not have any side effect to the app. No data will be stored as a result of successful or failed WP.com sign in.
    ///
    /// - SeeAlso `signIn`
    func authenticate(
        from viewController: UIViewController,
        prefersEphemeralWebBrowserSession: Bool,
        accountEmail: String? = nil,
        recoverDenyAccess: Bool = true
    ) async throws(AuthenticationError) -> String {
        let clientId = ApiCredentials.client
        let clientSecret = ApiCredentials.secret
        let redirectURI = "x-wordpress-app://oauth2-callback"

        var queries: [String: Any] = [
            "client_id": clientId,
            "redirect_uri": redirectURI,
            "response_type": "code",
            "scope": "global",
        ]
        if let accountEmail {
            queries["user_email"] = accountEmail
        }

        // Using Alamofire instead of URL to encode query string because URL do not encoded "+" (which may present
        // in user's email) in query. WP.com treat "+" in URL query as a whitespace, which cause the login page to
        // prepopulate the email address incorrectly, i.e. "foo+bar@baz.com" shows as "foo bar@baz.com"
        let authorizeURL = try? URLEncoding.queryString.encode(URLRequest(url: URL(string: "https://public-api.wordpress.com/oauth2/authorize")!), with: queries).url
        guard let authorizeURL else { throw .urlError(URLError(.badURL)) }

        let callbackURL = try await authorize(from: viewController, url: authorizeURL, prefersEphemeralWebBrowserSession: prefersEphemeralWebBrowserSession)

        do {
            return try await handleAuthorizeCallbackURL(callbackURL, clientId: clientId, clientSecret: clientSecret, redirectURI: redirectURI)
        } catch {
            if case .loginDenied = error, recoverDenyAccess {
                return try await self.recoverLoginDeniedError(viewController: viewController, accountEmail: accountEmail)
            } else {
                throw error
            }
        }
    }

    private func authorize(from viewController: UIViewController, url authorizeURL: URL, prefersEphemeralWebBrowserSession: Bool) async throws(AuthenticationError) -> URL {
        if let authenticator {
            return try authenticator(authorizeURL)
        }

        return try await withCheckedTypedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                let provider = WebAuthenticationPresentationAnchorProvider(anchor: viewController.view.window ?? UIWindow())
                let session = ASWebAuthenticationSession(url: authorizeURL, callbackURLScheme: "x-wordpress-app") { url, error in
                    let result: Result<URL, AuthenticationError>
                    if let url {
                        result = .success(url)
                    } else {
                        DDLogWarn("Error from authentication session: \(String(describing: error))")
                        result = .failure(.cancelled)
                    }
                    continuation(result)
                }
                session.prefersEphemeralWebBrowserSession = prefersEphemeralWebBrowserSession
                session.presentationContextProvider = provider
                session.start()
            }
        }
    }

    private func handleAuthorizeCallbackURL(
        _ url: URL,
        clientId: String,
        clientSecret: String,
        redirectURI: String
    ) async throws(AuthenticationError) -> String {
        guard let query = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems else {
            throw .invalidCallbackURL
        }

        let queryMap: [String: String] = query.reduce(into: [:]) { $0[$1.name] = $1.value }

        guard let code = queryMap["code"] else {
            if queryMap["error"] == "access_denied" {
                let message = Strings.accessDenied
                throw .loginDenied(message: message)
            }
            throw .invalidCallbackURL
        }

        var tokenRequest = URLRequest(url: URL(string: "https://public-api.wordpress.com/oauth2/token")!)
        tokenRequest.httpMethod = "POST"
        let parameters: [String: String] = [
            "grant_type": "authorization_code",
            "client_id": clientId,
            "client_secret": clientSecret,
            "redirect_uri": redirectURI,
            "code": code,
        ]

        do {
            tokenRequest = try URLEncodedFormParameterEncoder().encode(parameters, into: tokenRequest)
        } catch {
            wpAssertionFailure("Unexpected form encoding error", userInfo: ["error": "\(error)"])
            throw .unknown(error)
        }

        do {
            let urlSession = URLSession.shared
            let (data, _) = try await urlSession.data(for: tokenRequest)

            struct Response: Decodable {
                var accessToken: String
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let token = try decoder.decode(Response.self, from: data).accessToken

            return token
        } catch let error as URLError {
            throw .urlError(error)
        } catch let error as DecodingError {
            throw .parsing(error)
        } catch {
            DDLogError("Failed to parse token request response: \(error)")
            throw .unknown(error)
        }
    }

    // Present an alert to ask the user to re-authenticate after they tap the "Deny" button.
    private func recoverLoginDeniedError(viewController: UIViewController, accountEmail: String?) async throws(AuthenticationError) -> String {
        let reLogin = await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let alert = UIAlertController(
                    title: Strings.loginDeniedTitle,
                    message: Strings.loginDeniedAlertMessage(),
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: SharedStrings.Button.close, style: .cancel) { _ in
                    continuation.resume(returning: false)
                })
                alert.addAction(UIAlertAction(title: Strings.useDifferentAccount, style: .default) { _ in
                    continuation.resume(returning: true)
                })
                viewController.present(alert, animated: true)
            }
        }

        guard reLogin else {
            throw .loginAgainRejected
        }

        // Use an ephemeral session here to ignore the existing account in Safari and allow user to sign in with whatever account they'd like to use.
        return try await self.authenticate(from: viewController, prefersEphemeralWebBrowserSession: true, accountEmail: accountEmail, recoverDenyAccess: false)
    }
}

/// typed-throw version of `withCheckedThrowingContinuation`
private func withCheckedTypedThrowingContinuation<T, E: Error>(body: (@escaping ((Result<T, E>) -> Void)) -> Void) async throws(E) -> T {
    do {
        return try await withCheckedThrowingContinuation { continuation in
            body {
                continuation.resume(with: $0)
            }
        }
    } catch {
        throw (error as! E)
    }
}

private extension WordPressDotComAuthenticator.SignInError {
    var alertMessage: String? {
        switch self {
        case let .authentication(error):
            return error.alertMessage
        case .fetchUser:
            return Strings.fetchUserError
        case let .mismatchedEmail(expectedEmail):
            return Strings.mismatchedEmail(expectedEmail)
        case let .alreadySignedIn(signedInAccountEmail):
            return Strings.alreadySignedIn(signedInAccountEmail)
        case .loadingSites:
            return Strings.loadingSitesError
        }
    }
}

private extension WordPressDotComAuthenticator.AuthenticationError {
    var alertMessage: String? {
        switch self {
        case .cancelled:
            // `.cancelled` error is thrown when user taps the cancel button in the presented Safari view controller.
            // No need to show an alert for this error.
            return nil
        case .loginAgainRejected:
            // This error is originated from an alert. We don't need to show another alert for the error.
            return nil
        case let .loginDenied(message):
            return message
        case let .urlError(error):
            return error.localizedDescription
        case .invalidCallbackURL, .obtainAccessToken, .parsing, .unknown:
            // These errors are unexpected.
            wpAssertionFailure("WP.com web login failed", userInfo: ["error": "\(self)"])
            return SharedStrings.Error.generic
        }
    }
}

private enum Strings {
    static let accessDenied = NSLocalizedString("wpComLogin.error.accessDenied", value: "Access denied. You need to approve to log in to WordPress.com", comment: "Error message when user denies access to WordPress.com")
    static let loginDeniedTitle = NSLocalizedString("wpComLogin.loginDenied.title", value: "Login Cancelled", comment: "Title of alert shown when user cancels WordPress.com login")
    static let loginDeniedMessage = NSLocalizedString("wpComLogin.loginDenied.message", value: "You can sign in with a different account if you need a different one. Tap \"%@\" to start.", comment: "Message shown when user denies WordPress.com login, offering option to try with different account")
    static let useDifferentAccount = NSLocalizedString("wpComLogin.loginDenied.useDifferentAccount", value: "Use Different Account", comment: "Button title for signing in with a different WordPress.com account")
    static let fetchUserError = NSLocalizedString("wpComLogin.error.fetchUser", value: "Failed to load user details", comment: "Error message when failing to load user details during WordPress.com login")
    static let mismatchedEmail = NSLocalizedString("wpComLogin.error.mismatchedEmail", value: "Please sign in with email address %@", comment: "Error message when user signs in with an unexpected email address. The first argument is the expected email address")
    static let alreadySignedIn = NSLocalizedString("wpComLogin.error.alreadySignedIn", value: "You have already signed in with email address %@. Please sign out try again.", comment: "Error message when user signs in with an different account than the account that's alredy signed in. The first argument is the current signed-in account email address")
    static let loadingSitesError = NSLocalizedString("wpComLogin.error.loadingSites", value: "Your account's sites cannot be loaded. Please try again later.", comment: "Error message when failing to load account's site after signing in")

    static func loginDeniedAlertMessage() -> String {
        String(format: loginDeniedMessage, useDifferentAccount)
    }

    static func mismatchedEmail(_ email: String) -> String {
        String(format: mismatchedEmail, email)
    }

    static func alreadySignedIn(_ email: String) -> String {
        String(format: alreadySignedIn, email)
    }
}
