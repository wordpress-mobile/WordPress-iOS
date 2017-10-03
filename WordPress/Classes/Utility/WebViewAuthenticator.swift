import Foundation

class WebViewAuthenticator: NSObject {
    typealias Username = String
    typealias Password = String
    typealias Token = String

    enum Credentials {
        case dotCom(Username, Token)
        case siteLogin(URL, Username, Password)
    }

    let credentials: Credentials
    var userAgent: String?

    init(credentials: Credentials) {
        self.credentials = credentials
    }

    convenience init(dotComUsername username: Username, authToken: Token) {
        self.init(credentials: .dotCom(username, authToken))
    }

    convenience init(selfHostedUsername username: Username, password: Password, loginURL: URL) {
        self.init(credentials: .siteLogin(loginURL, username, password))
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

    func request(url: URL) -> URLRequest {
        return authenticatedRequest(url: url) ?? unauthenticatedRequest(url: url)
    }
}

private extension WebViewAuthenticator {
    func unauthenticatedRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    func body(url: URL) -> Data? {
        guard let encodedUsername = username.urlFormEncoded,
            let encodedUrl = url.absoluteString.urlFormEncoded else {
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
}

private extension String {
    var urlFormEncoded: String? {
        // https://url.spec.whatwg.org/#urlencoded-serializing
        let urlAllowedForm: CharacterSet = CharacterSet(charactersIn: "*-._").union(.alphanumerics)
        return addingPercentEncoding(withAllowedCharacters: urlAllowedForm)
    }
}
