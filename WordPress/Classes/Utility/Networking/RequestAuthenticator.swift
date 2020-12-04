import AutomatticTracks
import Foundation

/// Authenticator for requests to self-hosted sites, wp.com sites, including private
/// sites and atomic sites.
///
/// - Note: at some point I considered moving this module to the WordPressAuthenticator pod.
///     Unfortunately the effort required for this makes it unfeasible for me to focus on it
///     right now, as it involves also moving at least CookieJar, AuthenticationService and AtomicAuthenticationService over there as well. - @diegoreymendez
///
class RequestAuthenticator: NSObject {

    enum Error: Swift.Error {
        case atomicSiteWithoutDotComID(blog: Blog)
    }

    enum DotComAuthenticationType {
        case regular
        case regularMapped(siteID: Int)
        case atomic(loginURL: String)
        case privateAtomic(blogID: Int)
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
        guard let username = account.username,
            let token = account.authToken else {
                return nil
        }

        var authenticationType: DotComAuthenticationType = .regular

        if let blog = blog, let dotComID = blog.dotComID as? Int {

            if blog.isAtomic() {
                authenticationType = blog.isPrivate() ? .privateAtomic(blogID: dotComID) : .atomic(loginURL: blog.loginUrl())
            } else if blog.hasMappedDomain() {
                authenticationType = .regularMapped(siteID: dotComID)
            }
        }

        self.init(credentials: .dotCom(username: username, authToken: token, authenticationType: authenticationType))
    }

    @objc convenience init?(blog: Blog) {
        if let account = blog.account {
            self.init(account: account, blog: blog)
        } else if let username = blog.usernameForSite,
            let password = blog.password,
            let loginURL = URL(string: blog.loginUrl()) {
            self.init(credentials: .siteLogin(loginURL: loginURL, username: username, password: password))
        } else {
            DDLogError("Can't authenticate blog \(String(describing: blog.displayURL)) yet")
            return nil
        }
    }

    /// Potentially rewrites a request for authentication.
    ///
    /// This method will call the completion block with the request to be used.
    ///
    /// - Warning: On WordPress.com, this uses a special redirect system. It
    /// requires the web view to call `interceptRedirect(request:)` before
    /// loading any request.
    ///
    /// - Parameters:
    ///     - url: the URL to be loaded.
    ///     - cookieJar: a CookieJar object where the authenticator will look
    ///     for existing cookies.
    ///     - completion: this will be called with either the request for
    ///     authentication, or a request for the original URL.
    ///
    @objc func request(url: URL, cookieJar: CookieJar, completion: @escaping (URLRequest) -> Void) {
        switch self.credentials {
        case .dotCom(let username, let authToken, let authenticationType):
            requestForWPCom(
                url: url,
                cookieJar: cookieJar,
                username: username,
                authToken: authToken,
                authenticationType: authenticationType,
                completion: completion)
        case .siteLogin(let loginURL, let username, let password):
            requestForSelfHosted(
                url: url,
                loginURL: loginURL,
                cookieJar: cookieJar,
                username: username,
                password: password,
                completion: completion)
        }
    }

    private func requestForWPCom(url: URL, cookieJar: CookieJar, username: String, authToken: String, authenticationType: DotComAuthenticationType, completion: @escaping (URLRequest) -> Void) {

        switch authenticationType {
        case .regular:
            requestForWPCom(
                url: url,
                cookieJar: cookieJar,
                username: username,
                authToken: authToken,
                completion: completion)
        case .regularMapped(let siteID):
            requestForMappedWPCom(url: url,
                cookieJar: cookieJar,
                username: username,
                authToken: authToken,
                siteID: siteID,
                completion: completion)

        case .privateAtomic(let siteID):
            requestForPrivateAtomicWPCom(
                url: url,
                cookieJar: cookieJar,
                username: username,
                siteID: siteID,
                completion: completion)
        case .atomic(let loginURL):
            requestForAtomicWPCom(
                url: url,
                loginURL: loginURL,
                cookieJar: cookieJar,
                username: username,
                authToken: authToken,
                completion: completion)
        }
    }

    private func requestForSelfHosted(url: URL, loginURL: URL, cookieJar: CookieJar, username: String, password: String, completion: @escaping (URLRequest) -> Void) {

        func done() {
            let request = URLRequest(url: url)
            completion(request)
        }

        authenticationService.loadAuthCookiesForSelfHosted(into: cookieJar, loginURL: loginURL, username: username, password: password, success: {
            done()
        }) { error in
            // Make sure this error scenario isn't silently ignored.
            CrashLogging.logError(error)

            // Even if getting the auth cookies fail, we'll still try to load the URL
            // so that the user sees a reasonable error situation on screen.
            // We could opt to create a special screen but for now I'd rather users report
            // the issue when it happens.
            done()
        }
    }

    private func requestForPrivateAtomicWPCom(url: URL, cookieJar: CookieJar, username: String, siteID: Int, completion: @escaping (URLRequest) -> Void) {

        func done() {
            let request = URLRequest(url: url)
            completion(request)
        }

        // We should really consider refactoring how we retrieve the default account since it doesn't really use
        // a context at all...
        guard let account = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext).defaultWordPressComAccount() else {

            CrashLogging.logMessage("It shouldn't be possible to reach this point without an account.", properties: nil, level: .error)
            return
        }
        let authenticationService = AtomicAuthenticationService(account: account)

        authenticationService.loadAuthCookies(into: cookieJar, username: username, siteID: siteID, success: {
            done()
        }) { error in
            // Make sure this error scenario isn't silently ignored.
            CrashLogging.logError(error)

            // Even if getting the auth cookies fail, we'll still try to load the URL
            // so that the user sees a reasonable error situation on screen.
            // We could opt to create a special screen but for now I'd rather users report
            // the issue when it happens.
            done()
        }
    }

    private func requestForAtomicWPCom(url: URL, loginURL: String, cookieJar: CookieJar, username: String, authToken: String, completion: @escaping (URLRequest) -> Void) {

        func done() {
            // For non-private Atomic sites, proxy the request through wp-login like Calypso does.
            // If the site has SSO enabled auth should happen and we get redirected to our preview.
            // If SSO is not enabled wp-admin prompts for credentials, then redirected.
            var components = URLComponents(string: loginURL)
            var queryItems = components?.queryItems ?? []
            queryItems.append(URLQueryItem(name: "redirect_to", value: url.absoluteString))
            components?.queryItems = queryItems
            let requestURL = components?.url ?? url

            let request = URLRequest(url: requestURL)
            completion(request)
        }

        authenticationService.loadAuthCookiesForWPCom(into: cookieJar, username: username, authToken: authToken, success: {
            done()
        }) { error in
            // Make sure this error scenario isn't silently ignored.
            CrashLogging.logError(error)

            // Even if getting the auth cookies fail, we'll still try to load the URL
            // so that the user sees a reasonable error situation on screen.
            // We could opt to create a special screen but for now I'd rather users report
            // the issue when it happens.
            done()
        }
    }

    private func requestForMappedWPCom(url: URL, cookieJar: CookieJar, username: String, authToken: String, siteID: Int, completion: @escaping (URLRequest) -> Void) {
        func done() {
            guard
                let host = url.host,
                !host.contains(WPComDomain)
            else {
                // The requested URL is to the unmapped version of the domain,
                // so skip proxying the request through r-login.
                completion(URLRequest(url: url))
                return
            }

            let rlogin = "https://r-login.wordpress.com/remote-login.php?action=auth"
            guard var components = URLComponents(string: rlogin) else {
                // Safety net in case something unexpected changes in the future.
                DDLogError("There was an unexpected problem initializing URLComponents via the rlogin string.")
                completion(URLRequest(url: url))
                return
            }
            var queryItems = components.queryItems ?? []
            queryItems.append(contentsOf: [
                URLQueryItem(name: "host", value: host),
                URLQueryItem(name: "id", value: String(siteID)),
                URLQueryItem(name: "back", value: url.absoluteString)
            ])
            components.queryItems = queryItems
            let requestURL = components.url ?? url

            let request = URLRequest(url: requestURL)
            completion(request)
        }

        authenticationService.loadAuthCookiesForWPCom(into: cookieJar, username: username, authToken: authToken, success: {
            done()
        }) { error in
            // Make sure this error scenario isn't silently ignored.
            CrashLogging.logError(error)

            // Even if getting the auth cookies fail, we'll still try to load the URL
            // so that the user sees a reasonable error situation on screen.
            // We could opt to create a special screen but for now I'd rather users report
            // the issue when it happens.
            done()
        }
    }

    private func requestForWPCom(url: URL, cookieJar: CookieJar, username: String, authToken: String, completion: @escaping (URLRequest) -> Void) {

        func done() {
            let request = URLRequest(url: url)
            completion(request)
        }

        authenticationService.loadAuthCookiesForWPCom(into: cookieJar, username: username, authToken: authToken, success: {
            done()
        }) { error in
            // Make sure this error scenario isn't silently ignored.
            CrashLogging.logError(error)

            // Even if getting the auth cookies fail, we'll still try to load the URL
            // so that the user sees a reasonable error situation on screen.
            // We could opt to create a special screen but for now I'd rather users report
            // the issue when it happens.
            done()
        }
    }
}

private extension RequestAuthenticator {
    static let wordPressComLoginUrl = URL(string: "https://wordpress.com/wp-login.php")!
}

extension RequestAuthenticator {
    func isLogin(url: URL) -> Bool {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = nil

        return components?.url == RequestAuthenticator.wordPressComLoginUrl
    }
}
