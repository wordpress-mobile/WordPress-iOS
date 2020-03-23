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

    /// If true, the authenticator will assume that redirect URLs are allowed and
    /// won't use the special WordPress.com redirect URL
    ///
    @objc
    var safeRedirect = false

    // MARK: - Initializers

    init(credentials: Credentials) {
        self.credentials = credentials
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
        func done() {
            let request = URLRequest(url: url)
            completion(request)
        }

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
            // no-op
            break
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

        let authenticationService = AuthenticationService()

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

    /// Intercepts and rewrites any potential redirect after login.
    ///
    /// This should be called whenever a web view needs to decide if it should
    /// load a request. If this returns a non-nil value, the resulting request
    /// should be loaded instead.
    ///
    /// - Parameters:
    ///     - request: the request that was going to be loaded by the web view.
    ///
    /// - Returns: a request to be loaded instead. If `nil`, the original
    /// request should continue loading.
    ///
    /*
    @objc func interceptRedirect(request: URLRequest) -> URLRequest? {
        guard let url = request.url,
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            components.scheme == "https",
            components.host == "wordpress.com",
            let encodedRedirect = components
                .queryItems?
                .first(where: { $0.name == WebViewAuthenticator.redirectParameter })?
                .value,
            let redirect = encodedRedirect.removingPercentEncoding,
            let redirectUrl = URL(string: redirect) else {
                return nil
        }

        return URLRequest(url: redirectUrl)
    }
 */

    /// Rewrites a request for authentication.
    ///
    /// This method will always return an authenticated request. If you want to
    /// authenticate only if needed, by inspecting the existing cookies, use
    /// request(url:cookieJar:completion:) instead
    ///
    func authenticatedRequest(url: URL) -> URLRequest {
        /*
        let authenticationService = AuthenticationService()
        
        authenticationService.getAuthCookies(success: { cookies in
            
            webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
        }) { error in
            
        }*/

        var request = URLRequest(url: loginURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = body(url: url)
        if let authToken = authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
}

private extension WebViewAuthenticator {
    func request(url: URL, authenticated: Bool) -> URLRequest {
        if authenticated {
            return authenticatedRequest(url: url)
        } else {
            return unauthenticatedRequest(url: url)
        }
    }

    func unauthenticatedRequest(url: URL) -> URLRequest {
        return URLRequest(url: url)
    }

    func body(url: URL) -> Data? {
        guard let redirectedUrl = redirectUrl(url: url.absoluteString) else {
                return nil
        }
        var parameters = [URLQueryItem]()
        parameters.append(URLQueryItem(name: "log", value: username))
        if let password = password {
            parameters.append(URLQueryItem(name: "pwd", value: password))
        }
        parameters.append(URLQueryItem(name: "rememberme", value: "true"))
        parameters.append(URLQueryItem(name: "redirect_to", value: redirectedUrl))
        var components = URLComponents()
        components.queryItems = parameters

        return components.percentEncodedQuery?.data(using: .utf8)
    }

    func redirectUrl(url: String) -> String? {
        guard case .dotCom = credentials,
            let escapedUrl = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            !safeRedirect else {
            return url
        }

        return self.url(string: "https://wordpress.com/", parameters: [WebViewAuthenticator.redirectParameter: escapedUrl])?.absoluteString
    }

    func url(string: String, parameters: [String: String]) -> URL? {
        guard var components = URLComponents(string: string) else {
            return nil
        }
        components.queryItems = parameters.map({ (key, value) in
            return URLQueryItem(name: key, value: value)
        })
        return components.url
    }

    var username: String {
        switch credentials {
        case .dotCom(let username, _, _):
            return username
        case .siteLogin(_, let username, _):
            return username
        }
    }

    var password: String? {
        switch credentials {
        case .dotCom:
            return nil
        case .siteLogin(_, _, let password):
            return password
        }
    }

    var authToken: String? {
        if case let .dotCom(_, authToken, _) = credentials {
            return authToken
        }
        switch credentials {
        case .dotCom(_, let authToken, _):
            return authToken
        case .siteLogin:
            return nil
        }
    }

    func cookieURL(for url: URL) -> URL {
        switch credentials {
        case .dotCom(_, _, let authenticationType):
            switch authenticationType {
            case .regular:
                return WebViewAuthenticator.wordPressComLoginUrl
            case .atomic:
                return url
            }
        case .siteLogin(let url, _, _):
            return url
        }
    }

    var loginURL: URL {
        switch credentials {
        case .dotCom(_, _, let authenticationType):
            switch authenticationType {
            case .regular:
                return WebViewAuthenticator.wordPressComLoginUrl
            case .atomic(let blogID):
                return URL(string: "google.com")!
            }
        case .siteLogin(let url, _, _):
            return url
        }
    }

    static let wordPressComLoginUrl = URL(string: "https://wordpress.com/wp-login.php")!
    static let redirectParameter = "wpios_redirect"
}

extension WebViewAuthenticator {
    func isLogin(url: URL) -> Bool {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = nil

        return components?.url == WebViewAuthenticator.wordPressComLoginUrl
    }
}
