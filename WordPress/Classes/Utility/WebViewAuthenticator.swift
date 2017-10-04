import Foundation

class WebViewAuthenticator: NSObject {
    enum Credentials {
        case dotCom(username: String, authToken: String)
        case siteLogin(loginURL: URL, username: String, password: String)
    }

    let credentials: Credentials
    var userAgent: String?

    init(credentials: Credentials) {
        self.credentials = credentials
    }

    convenience init?(account: WPAccount) {
        guard let username = account.username,
            let token = account.authToken else {
                return nil;
        }
        self.init(credentials: .dotCom(username: username, authToken: token))
    }

    convenience init?(blog: Blog) {
        if let account = blog.account {
            self.init(account: account)
        } else if let username = blog.usernameForSite,
            let password = blog.password,
            let loginURL = URL(string: blog.loginUrl())
        {
            self.init(credentials: .siteLogin(loginURL: loginURL, username: username, password: password))
        } else {
            DDLogError("Can't authenticate blog \(String(describing: blog.displayURL)) yet")
            return nil
        }
    }

    func authenticatedRequest(url: URL) -> URLRequest? {
        var request = URLRequest(url: loginURL)
        request.httpMethod = "POST"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = body(url: url)
        if let authToken = authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    func request(url: URL, cookieJar: CookieJar, completion: @escaping (URLRequest) -> Void) {
        cookieJar.hasCookie(url: loginURL, username: username) { [weak self] (hasCookie) in
            guard let authenticator = self else {
                return
            }

            let request = authenticator.request(url: url, authenticated: !hasCookie)
            completion(request)
        }
    }

    func interceptRedirect(request: URLRequest) -> URLRequest? {
        guard let url = request.url,
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            components.scheme == "https",
            components.host == "wordpress.com",
            let encodedRedirect = components
                .queryItems?
                .first(where: { $0.name == WebViewAuthenticator.redirectParameter })?
                .value,
            let redirect = encodedRedirect.removingPercentEncoding,
            let redirectUrl = URL(string: redirect)
            else {
                return nil
        }

        return URLRequest(url: redirectUrl)
    }
}

private extension WebViewAuthenticator {
    func request(url: URL, authenticated: Bool) -> URLRequest {
        guard authenticated else {
            return unauthenticatedRequest(url: url)
        }
        return authenticatedRequest(url: url) ?? unauthenticatedRequest(url: url)
    }

    func unauthenticatedRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    func body(url: URL) -> Data? {
        guard let encodedUsername = username.urlFormEncoded,
            let encodedUrl = redirectUrl(url: url.absoluteString)?.urlFormEncoded else {
            return nil
        }
        let encodedPassword = password?.urlFormEncoded

        var parameters = "log=\(encodedUsername)"
        if let encodedPassword = encodedPassword {
            parameters += "&pwd=\(encodedPassword)"
        }
        parameters += "&redirect_to=\(encodedUrl)"

        return parameters.data(using: .utf8)
    }

    func redirectUrl(url: String) -> String? {
        guard case .dotCom(_,_) = credentials else {
            return url
        }
        guard let encodedUrl = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return "https://wordpress.com/?\(WebViewAuthenticator.redirectParameter)=\(encodedUrl)"
    }

    var username: String {
        switch credentials {
        case .dotCom(let username, _):
            return username
        case .siteLogin(_, let username, _):
            return username
        }
    }

    var password: String? {
        switch credentials {
        case .dotCom(_, _):
            return nil
        case .siteLogin(_, _, let password):
            return password
        }
    }

    var authToken: String? {
        if case let .dotCom(_, authToken) = credentials {
            return authToken
        }
        switch credentials {
        case .dotCom(_, let authToken):
            return authToken
        case .siteLogin(_, _, _):
            return nil
        }
    }

    var loginURL: URL {
        switch credentials {
        case .dotCom(_, _):
            return WebViewAuthenticator.wordPressComLoginUrl
        case .siteLogin(let url, _, _):
            return url
        }
    }

    static let wordPressComLoginUrl = URL(string: "https://wordpress.com/wp-login.php")!
    static let redirectParameter = "wpios_redirect"
}

private extension String {
    var urlFormEncoded: String? {
        // https://url.spec.whatwg.org/#urlencoded-serializing
        let urlAllowedForm: CharacterSet = CharacterSet(charactersIn: "*-._").union(.alphanumerics)
        return addingPercentEncoding(withAllowedCharacters: urlAllowedForm)
    }
}
