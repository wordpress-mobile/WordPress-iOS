import AutomatticTracks
import Foundation
import WordPressData

/// Authenticator for requests to self-hosted sites, wp.com sites, including private
/// sites and atomic sites.
///
/// - Note: at some point I considered moving this module to the WordPressAuthenticator pod.
///     Unfortunately the effort required for this makes it unfeasible for me to focus on it
///     right now, as it involves also moving at least CookieJar, AuthenticationService and AtomicAuthenticationService over there as well. - @diegoreymendez
///
/// Both stored properties are immutable and `AuthenticationService` is stateless,
/// so instances can be built on one queue and used on another.
class RequestAuthenticator: NSObject, @unchecked Sendable {

    enum DotComAuthenticationType {
        case regular
        case regularMapped(siteID: Int)
        case atomic(loginURL: String)
        case privateAtomic(blogID: Int)
    }

    enum WPNavigationActionType {
        case reload
        case allow
    }

    enum Credentials {
        case dotCom(username: String, authToken: String, authenticationType: DotComAuthenticationType)
        case siteLogin(loginURL: URL, username: String, password: String)
    }

    fileprivate let credentials: Credentials

    // MARK: - Services

    private let authenticationService: AuthenticationService

    // MARK: - Initializers

    init(credentials: Credentials, authenticationService: AuthenticationService = AuthenticationService()) {
        self.credentials = credentials
        self.authenticationService = authenticationService
    }

    @objc convenience init?(account: WPAccount, blog: Blog? = nil) {
        guard let token = account.authToken else {
                return nil
        }

        var authenticationType: DotComAuthenticationType = .regular

        if let blog, let dotComID = blog.dotComID as? Int {
            if blog.isAtomic {
                authenticationType = blog.isPrivate ? .privateAtomic(blogID: dotComID) : .atomic(loginURL: blog.loginURL?.absoluteString ?? "")
            } else if blog.hasMappedDomain {
                authenticationType = .regularMapped(siteID: dotComID)
            }
        }

        self.init(credentials: .dotCom(username: account.username, authToken: token, authenticationType: authenticationType))
    }

    @objc convenience init?(blog: Blog) {
        if let account = blog.account {
            self.init(account: account, blog: blog)
        } else if let username = blog.effectiveUsername,
            let password = blog.password,
            let loginURL = blog.loginURL {
            self.init(credentials: .siteLogin(loginURL: loginURL, username: username, password: password))
        } else {
            DDLogError("Can't authenticate blog \(String(describing: blog.displayURL)) yet")
            return nil
        }
    }

    /// Potentially rewrites a request for authentication.
    ///
    /// - Warning: On WordPress.com, this uses a special redirect system. It
    /// requires the web view to call `interceptRedirect(request:)` before
    /// loading any request.
    ///
    /// - Parameters:
    ///     - url: the URL to be loaded.
    ///     - cookieJar: a CookieJar object where the authenticator will look
    ///     for existing cookies.
    /// - Returns: either the request for authentication, or a request for the
    ///     original URL.
    ///
    @MainActor
    func request(url: URL, cookieJar: CookieJar) async -> URLRequest {
        switch self.credentials {
        case .dotCom(let username, let authToken, let authenticationType):
            return await requestForWPCom(
                url: url,
                cookieJar: cookieJar,
                username: username,
                authToken: authToken,
                authenticationType: authenticationType)
        case .siteLogin(let loginURL, let username, let password):
            return await requestForSelfHosted(
                url: url,
                loginURL: loginURL,
                cookieJar: cookieJar,
                username: username,
                password: password)
        }
    }

    /// Calls the completion block on the main thread with the result of `request(url:cookieJar:)`.
    func request(url: URL, cookieJar: CookieJar, completion: @escaping (URLRequest) -> Void) {
        Task { @MainActor in
            completion(await request(url: url, cookieJar: cookieJar))
        }
    }

    @MainActor
    private func requestForWPCom(url: URL, cookieJar: CookieJar, username: String, authToken: String, authenticationType: DotComAuthenticationType) async -> URLRequest {

        switch authenticationType {
        case .regular:
            return await requestForWPCom(
                url: url,
                cookieJar: cookieJar,
                username: username,
                authToken: authToken)
        case .regularMapped(let siteID):
            return await requestForMappedWPCom(url: url,
                cookieJar: cookieJar,
                username: username,
                authToken: authToken,
                siteID: siteID)

        case .privateAtomic(let siteID):
            return await requestForPrivateAtomicWPCom(
                url: url,
                cookieJar: cookieJar,
                username: username,
                siteID: siteID)
        case .atomic(let loginURL):
            return await requestForAtomicWPCom(
                url: url,
                loginURL: loginURL,
                cookieJar: cookieJar,
                username: username,
                authToken: authToken)
        }
    }

    @MainActor
    private func requestForSelfHosted(url: URL, loginURL: URL, cookieJar: CookieJar, username: String, password: String) async -> URLRequest {
        do {
            try await authenticationService.loadAuthCookiesForSelfHosted(into: cookieJar, loginURL: loginURL, username: username, password: password)
        } catch {
            // Make sure this error scenario isn't silently ignored.
            logErrorIfNeeded(error)

            // Even if getting the auth cookies fail, we'll still try to load the URL
            // so that the user sees a reasonable error situation on screen.
            // We could opt to create a special screen but for now I'd rather users report
            // the issue when it happens.
        }

        return URLRequest(url: url)
    }

    @MainActor
    private func requestForPrivateAtomicWPCom(url: URL, cookieJar: CookieJar, username: String, siteID: Int) async -> URLRequest {
        // We should really consider refactoring how we retrieve the default account since it doesn't really use
        // a context at all...
        let context = ContextManager.shared.mainContext
        guard let account = try? WPAccount.lookupDefaultWordPressComAccount(in: context) else {
            WordPressAppDelegate.crashLogging?.logMessage("It shouldn't be possible to reach this point without an account.", properties: nil, level: .error)
            return URLRequest(url: url)
        }
        let authenticationService = AtomicAuthenticationService(account: account)

        do {
            try await authenticationService.loadAuthCookies(into: cookieJar, username: username, siteID: siteID)
        } catch {
            // Make sure this error scenario isn't silently ignored.
            logErrorIfNeeded(error)

            // Even if getting the auth cookies fail, we'll still try to load the URL
            // so that the user sees a reasonable error situation on screen.
            // We could opt to create a special screen but for now I'd rather users report
            // the issue when it happens.
        }

        return URLRequest(url: url)
    }

    @MainActor
    private func requestForAtomicWPCom(url: URL, loginURL: String, cookieJar: CookieJar, username: String, authToken: String) async -> URLRequest {
        do {
            try await authenticationService.loadAuthCookiesForWPCom(into: cookieJar, username: username, authToken: authToken)
        } catch {
            // Make sure this error scenario isn't silently ignored.
            logErrorIfNeeded(error)

            // Even if getting the auth cookies fail, we'll still try to load the URL
            // so that the user sees a reasonable error situation on screen.
            // We could opt to create a special screen but for now I'd rather users report
            // the issue when it happens.
        }

        // For non-private Atomic sites, proxy the request through wp-login like Calypso does.
        // If the site has SSO enabled auth should happen and we get redirected to our preview.
        // If SSO is not enabled wp-admin prompts for credentials, then redirected.
        var components = URLComponents(string: loginURL)
        var queryItems = components?.queryItems ?? []
        queryItems.append(URLQueryItem(name: "redirect_to", value: url.absoluteString))
        components?.queryItems = queryItems
        let requestURL = components?.url ?? url

        return URLRequest(url: requestURL)
    }

    @MainActor
    private func requestForMappedWPCom(url: URL, cookieJar: CookieJar, username: String, authToken: String, siteID: Int) async -> URLRequest {
        do {
            try await authenticationService.loadAuthCookiesForWPCom(into: cookieJar, username: username, authToken: authToken)
        } catch {
            // Make sure this error scenario isn't silently ignored.
            logErrorIfNeeded(error)

            // Even if getting the auth cookies fail, we'll still try to load the URL
            // so that the user sees a reasonable error situation on screen.
            // We could opt to create a special screen but for now I'd rather users report
            // the issue when it happens.
        }

        guard
            let host = url.host,
            !host.contains(WPComDomain)
        else {
            // The requested URL is to the unmapped version of the domain,
            // so skip proxying the request through r-login.
            return URLRequest(url: url)
        }

        let rlogin = "https://r-login.wordpress.com/remote-login.php?action=auth"
        guard var components = URLComponents(string: rlogin) else {
            // Safety net in case something unexpected changes in the future.
            DDLogError("There was an unexpected problem initializing URLComponents via the rlogin string.")
            return URLRequest(url: url)
        }
        var queryItems = components.queryItems ?? []
        queryItems.append(contentsOf: [
            URLQueryItem(name: "host", value: host),
            URLQueryItem(name: "id", value: String(siteID)),
            URLQueryItem(name: "back", value: url.absoluteString)
        ])
        components.queryItems = queryItems
        let requestURL = components.url ?? url

        return URLRequest(url: requestURL)
    }

    @MainActor
    private func requestForWPCom(url: URL, cookieJar: CookieJar, username: String, authToken: String) async -> URLRequest {
        do {
            try await authenticationService.loadAuthCookiesForWPCom(into: cookieJar, username: username, authToken: authToken)
        } catch {
            // Make sure this error scenario isn't silently ignored.
            logErrorIfNeeded(error)

            // Even if getting the auth cookies fail, we'll still try to load the URL
            // so that the user sees a reasonable error situation on screen.
            // We could opt to create a special screen but for now I'd rather users report
            // the issue when it happens.
        }

        return URLRequest(url: url)
    }

    private func logErrorIfNeeded(_ error: Swift.Error) {

        if let cookieError = error as? AuthenticationService.RequestAuthCookieError {
            WordPressAppDelegate.crashLogging?.logMessage(cookieError.localizedDescription)
            return
        }

        let nsError = error as NSError

        switch nsError.code {
        case NSURLErrorTimedOut, NSURLErrorNotConnectedToInternet:
            return
        default:
            WordPressAppDelegate.crashLogging?.logError(error)
        }
    }
}

private extension RequestAuthenticator {
    static let wordPressComLoginUrls: Set<URL> = [
        URL(string: "https://wordpress.com/wp-login.php")!,
        URL(string: "https://wordpress.com/log-in")!
    ]
}

extension RequestAuthenticator {
    func isLogin(url: URL) -> Bool {
        // For some reason, the in-app browser may open Safari when tapping certain links.
        // The "login URLs" are displayed within the in-app browser, which includes atomic site login (wp-login.php)
        // and WordPress.com sign-in web pages.

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = nil
        guard let normalized = components?.url else { return false }

        if RequestAuthenticator.wordPressComLoginUrls.contains(normalized) {
            return true
        }

        if case let .dotCom(_, _, .atomic(loginURL)) = credentials, normalized.absoluteString == loginURL {
            return true
        }

        return false
    }
}

// MARK: Navigation Validator
extension RequestAuthenticator {
    /// Validates that the navigation worked as expected then provides a recommendation on if the screen should reload or not.
    @MainActor
    func decideActionFor(response: URLResponse, cookieJar: CookieJar) async -> WPNavigationActionType {
        guard needsAuthenticationRecovery(response) else {
            return .allow
        }

        await cookieJar.removeWordPressComCookies()
        return .reload
    }

    /// Completion-handler variant of `decideActionFor(response:cookieJar:)`.
    ///
    /// Calls the completion block synchronously when the action is `.allow`, otherwise on the main thread.
    func decideActionFor(response: URLResponse, cookieJar: CookieJar, completion: @escaping (WPNavigationActionType) -> Void) {
        guard needsAuthenticationRecovery(response) else {
            completion(.allow)
            return
        }

        Task { @MainActor in
            completion(await decideActionFor(response: response, cookieJar: cookieJar))
        }
    }

    private func needsAuthenticationRecovery(_ response: URLResponse) -> Bool {
        switch self.credentials {
        case .dotCom:
            return didEncouterRecoverableChallenge(response)
        case .siteLogin:
            return false
        }
    }

    private func didEncouterRecoverableChallenge(_ response: URLResponse) -> Bool {
        guard let url = response.url?.absoluteString else {
            return false
        }

        if url.contains("r-login.wordpress.com") || url.contains("wordpress.com/log-in?") {
            return true
        }

        guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
            return false
        }

        return 400 <= statusCode && statusCode < 500
    }
}
