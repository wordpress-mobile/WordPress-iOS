import AutomatticTracks
import Foundation

class AuthenticationService {

    static let wpComLoginEndpoint = "https://wordpress.com/wp-login.php"

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
                    CrashLogging.logError(error)

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

        // We don't want these cookies loaded onto all of our requests
        let session = URLSession(configuration: .ephemeral)
        var request = URLRequest(url: loginURL)

        request.httpMethod = "POST"
        request.httpBody = body(withParameters: [
            "log": username,
            "pwd": password,
            "rememberme": "true"
        ])

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                failure(error)
                return
            }

            let cookies = session.configuration.httpCookieStorage?.cookies ?? [HTTPCookie]()
            success(cookies)
        }

        task.resume()
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
                    success()
                    return
                }

                self.getAuthCookiesForWPCom(username: username, authToken: authToken, success: { cookies in
                    cookieJar.setCookies(cookies) {
                        success()
                    }
                }) { error in
                    // Make sure this error scenario isn't silently ignored.
                    CrashLogging.logError(error)

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

        // We don't want these cookies loaded onto all of our requests
        let session = URLSession(configuration: .ephemeral)

        let endpoint = AuthenticationService.wpComLoginEndpoint
        let url = URL(string: endpoint)!
        var request = URLRequest(url: url)

        request.httpMethod = "POST"
        request.httpBody = body(withParameters: [
            "log": username,
            "rememberme": "true"
        ])
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                failure(error)
                return
            }

            let cookies = session.configuration.httpCookieStorage?.cookies ?? [HTTPCookie]()
            success(cookies)
        }

        task.resume()
    }

    // MARK: - Request Construction

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
}
