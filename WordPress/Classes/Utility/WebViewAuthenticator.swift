import AutomatticTracks
import Foundation

/// Encapsulates all the authentication logic for web views.
///
/// This objects is in charge of deciding when a web view should be authenticated,
/// and rewriting requests to do so.
///
/// Our current authentication system is based on posting to wp-login.php and
/// taking advantage of the `redirect_to` parameter. In the specific case of
/// WordPress.com, we sometimes want to pre-authenticate the user when visiting
/// URLs that we're not sure if they are hosted there (e.g. mapped domains).
///
/// Since WordPress.com doesn't allow redirects to external URLs, we use a
/// special WordPress.com URL that includes the target URL, and extract that on
/// `interceptRedirect(request:)`. You should call that from your web view's
/// delegate method, when deciding if a request or redirect should continue.
///
class WebViewAuthenticator: NSObject {

    enum Error: Swift.Error {
        case atomicSiteWithoutDotComID(blog: Blog)
    }

    enum DotComAuthenticationType {
        case regular
        case atomic(blogID: Int)
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

        let authenticationType: DotComAuthenticationType

        if let blog = blog,
            blog.isAtomic() {

            guard let blogID = blog.dotComID as? Int else {
                CrashLogging.logError(Error.atomicSiteWithoutDotComID(blog: blog))
                return nil
            }

            authenticationType = .atomic(blogID: blogID)
        } else {
            authenticationType = .regular
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

    func requestForWPCom(url: URL, cookieJar: CookieJar, username: String, authToken: String, authenticationType: DotComAuthenticationType, completion: @escaping (URLRequest) -> Void) {

        switch authenticationType {
        case .regular:
            requestForWPCom(
                url: url,
                cookieJar: cookieJar,
                username: username,
                authToken: authToken,
                completion: completion)
        case .atomic(let siteID):
            requestForAtomicWPCom(
                url: url,
                cookieJar: cookieJar,
                username: username,
                siteID: siteID,
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

    private func requestForAtomicWPCom(url: URL, cookieJar: CookieJar, username: String, siteID: Int, completion: @escaping (URLRequest) -> Void) {

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

private extension WebViewAuthenticator {
    static let wordPressComLoginUrl = URL(string: "https://wordpress.com/wp-login.php")!
}

extension WebViewAuthenticator {
    func isLogin(url: URL) -> Bool {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = nil

        return components?.url == WebViewAuthenticator.wordPressComLoginUrl
    }
}
