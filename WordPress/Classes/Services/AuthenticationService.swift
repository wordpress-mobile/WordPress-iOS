import AutomatticTracks
import Foundation

class AuthenticationService {

    static let wpComLoginEndpoint = "https://wordpress.com/wp-login.php"

    enum RequestAuthCookieError: Error, LocalizedError {
        case wpcomCookieNotReturned

        public var errorDescription: String? {
            switch self {
            case .wpcomCookieNotReturned:
                return "Response to request for auth cookie for WP.com site failed to return cookie."
            }
        }
    }

    // MARK: - Self Hosted

    func loadAuthCookiesForSelfHosted(
        into cookieJar: CookieJar,
        loginURL: URL,
        username: String,
        password: String,
        success: @escaping () -> Void,
        failure: @escaping (Error) -> Void) {

        cookieJar.hasWordPressSelfHostedAuthCookie(for: loginURL, username: username) { hasCookie in
                guard !hasCookie else {
                    success()
                    return
                }

                self.getAuthCookiesForSelfHosted(loginURL: loginURL, username: username, password: password, success: { cookies in
                    cookieJar.setCookies(cookies) {
                        success()
                    }

                    cookieJar.hasWordPressSelfHostedAuthCookie(for: loginURL, username: username) { hasCookie in
                        print("Has cookie: \(hasCookie)")
                    }
                }) { error in
                    // Make sure this error scenario isn't silently ignored.
                    WordPressAppDelegate.crashLogging?.logError(error)

                    // Even if getting the auth cookies fail, we'll still try to load the URL
                    // so that the user sees a reasonable error situation on screen.
                    // We could opt to create a special screen but for now I'd rather users report
                    // the issue when it happens.
                    failure(error)
                }
        }
    }

    func getAuthCookiesForSelfHosted(
        loginURL: URL,
        username: String,
        password: String,
        success: @escaping (_ cookies: [HTTPCookie]) -> Void,
        failure: @escaping (Error) -> Void) {

        let headers = [String: String]()
        let parameters = [
            "log": username,
            "pwd": password,
            "rememberme": "true"
        ]

        requestAuthCookies(
            from: loginURL,
            headers: headers,
            parameters: parameters,
            success: success,
            failure: failure)
    }

    // MARK: - WP.com

    func loadAuthCookiesForWPCom(
        into cookieJar: CookieJar,
        username: String,
        authToken: String,
        success: @escaping () -> Void,
        failure: @escaping (Error) -> Void) {

        cookieJar.hasWordPressComAuthCookie(
            username: username,
            atomicSite: false) { hasCookie in

                guard !hasCookie else {
                    // The stored cookie can be stale but we'll try to use it and refresh it if the request fails. 
                    success()
                    return
                }

                self.getAuthCookiesForWPCom(username: username, authToken: authToken, success: { cookies in
                    cookieJar.setCookies(cookies) {

                        cookieJar.hasWordPressComAuthCookie(username: username, atomicSite: false) { hasCookie in
                            guard hasCookie else {
                                failure(RequestAuthCookieError.wpcomCookieNotReturned)
                                return
                            }
                            success()
                        }

                    }
                }) { error in
                    // Make sure this error scenario isn't silently ignored.
                    WordPressAppDelegate.crashLogging?.logError(error)

                    // Even if getting the auth cookies fail, we'll still try to load the URL
                    // so that the user sees a reasonable error situation on screen.
                    // We could opt to create a special screen but for now I'd rather users report
                    // the issue when it happens.
                    failure(error)
                }
        }
    }

    func getAuthCookiesForWPCom(
        username: String,
        authToken: String,
        success: @escaping (_ cookies: [HTTPCookie]) -> Void,
        failure: @escaping (Error) -> Void) {

        let loginURL = URL(string: AuthenticationService.wpComLoginEndpoint)!
        let headers = [
            "Authorization": "Bearer \(authToken)"
        ]
        let parameters = [
            "log": username,
            "rememberme": "true"
        ]

        requestAuthCookies(
            from: loginURL,
            headers: headers,
            parameters: parameters,
            success: success,
            failure: failure)
    }

    // MARK: - Request Construction

    private func requestAuthCookies(
        from url: URL,
        headers: [String: String],
        parameters: [String: String],
        success: @escaping (_ cookies: [HTTPCookie]) -> Void,
        failure: @escaping (Error) -> Void) {

        // We don't want these cookies persisted in other sessions
        let session = URLSession(configuration: .ephemeral)
        var request = URLRequest(url: url)

        request.httpMethod = "POST"
        request.httpBody = body(withParameters: parameters)

        headers.forEach { (key, value) in
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.setValue(WPUserAgent.wordPress(), forHTTPHeaderField: "User-Agent")

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    failure(error)
                }
                return
            }

            // The following code is a bit complicated to read, apologies.
            // We're retrieving all cookies from the "Set-Cookie" header manually, and combining
            // those cookies with the ones from the current session.  The reason behind this is that
            // iOS's URLSession processes the cookies from such header before this callback is executed,
            // whereas OHTTPStubs.framework doesn't (the cookies are left in the header fields of
            // the response).  The only way to combine both is to just add them together here manually.
            //
            // To know if you can remove this, you'll have to test this code live and in our unit tests
            // and compare the session cookies.
            let responseCookies = self.cookies(from: response, loginURL: url)
            let cookies = (session.configuration.httpCookieStorage?.cookies ?? [HTTPCookie]()) + responseCookies
            DispatchQueue.main.async {
                success(cookies)
            }
        }

        task.resume()
    }

    private func body(withParameters parameters: [String: String]) -> Data? {
        var queryItems = [URLQueryItem]()

        for parameter in parameters {
            let queryItem = URLQueryItem(name: parameter.key, value: parameter.value)
            queryItems.append(queryItem)
        }

        var components = URLComponents()
        components.queryItems = queryItems

        return components.percentEncodedQuery?.data(using: .utf8)
    }

    // MARK: - Response Parsing

    private func cookies(from response: URLResponse?, loginURL: URL) -> [HTTPCookie] {
        guard let httpResponse = response as? HTTPURLResponse,
            let headers = httpResponse.allHeaderFields as? [String: String] else {
                return []
        }

        return HTTPCookie.cookies(withResponseHeaderFields: headers, for: loginURL)
    }
}
