import AutomatticTracks
import Foundation
import WordPressShared
import WordPressSharedUI

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

    @MainActor
    func loadAuthCookiesForSelfHosted(
        into cookieJar: CookieJar,
        loginURL: URL,
        username: String,
        password: String
    ) async throws {
        guard await !cookieJar.hasWordPressSelfHostedAuthCookie(for: loginURL, username: username) else {
            return
        }

        let cookies: [HTTPCookie]
        do {
            cookies = try await getAuthCookiesForSelfHosted(loginURL: loginURL, username: username, password: password)
        } catch {
            // Make sure this error scenario isn't silently ignored.
            WordPressAppDelegate.crashLogging?.logError(error)
            throw error
        }

        await cookieJar.setCookies(cookies)
    }

    @MainActor
    private func getAuthCookiesForSelfHosted(
        loginURL: URL,
        username: String,
        password: String
    ) async throws -> [HTTPCookie] {
        let headers = [String: String]()
        let parameters = [
            "log": username,
            "pwd": password,
            "rememberme": "true"
        ]

        return try await requestAuthCookies(from: loginURL, headers: headers, parameters: parameters)
    }

    // MARK: - WP.com

    @MainActor
    func loadAuthCookiesForWPCom(
        into cookieJar: CookieJar,
        username: String,
        authToken: String
    ) async throws {
        guard await !cookieJar.hasWordPressComAuthCookie(username: username, atomicSite: false) else {
            // The stored cookie can be stale but we'll try to use it and refresh it if the request fails.
            return
        }

        let cookies: [HTTPCookie]
        do {
            cookies = try await getAuthCookiesForWPCom(username: username, authToken: authToken)
        } catch {
            // Make sure this error scenario isn't silently ignored.
            WordPressAppDelegate.crashLogging?.logError(error)
            throw error
        }

        await cookieJar.setCookies(cookies)

        guard await cookieJar.hasWordPressComAuthCookie(username: username, atomicSite: false) else {
            throw RequestAuthCookieError.wpcomCookieNotReturned
        }
    }

    @MainActor
    private func getAuthCookiesForWPCom(username: String, authToken: String) async throws -> [HTTPCookie] {
        let loginURL = URL(string: AuthenticationService.wpComLoginEndpoint)!
        let headers = [
            "Authorization": "Bearer \(authToken)"
        ]
        let parameters = [
            "log": username,
            "rememberme": "true"
        ]

        return try await requestAuthCookies(from: loginURL, headers: headers, parameters: parameters)
    }

    // MARK: - Request Construction

    @MainActor
    private func requestAuthCookies(
        from url: URL,
        headers: [String: String],
        parameters: [String: String]
    ) async throws -> [HTTPCookie] {
        // We don't want these cookies persisted in other sessions
        let session = URLSession(configuration: .ephemeral)
        var request = URLRequest(url: url)

        request.httpMethod = "POST"
        request.httpBody = body(withParameters: parameters)

        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.setValue(WPUserAgent.wordPress(), forHTTPHeaderField: "User-Agent")

        let (_, response) = try await session.data(for: request)

        // The following code is a bit complicated to read, apologies.
        // We're retrieving all cookies from the "Set-Cookie" header manually, and combining
        // those cookies with the ones from the current session. The reason behind this is that
        // iOS's URLSession processes the cookies from such header before the request returns,
        // whereas OHTTPStubs.framework doesn't (the cookies are left in the header fields of
        // the response). The only way to combine both is to just add them together here manually.
        //
        // To know if you can remove this, you'll have to test this code live and in our unit tests
        // and compare the session cookies.
        let responseCookies = self.cookies(from: response, loginURL: url)
        return (session.configuration.httpCookieStorage?.cookies ?? [HTTPCookie]()) + responseCookies
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

    private func cookies(from response: URLResponse, loginURL: URL) -> [HTTPCookie] {
        guard let httpResponse = response as? HTTPURLResponse,
            let headers = httpResponse.allHeaderFields as? [String: String] else {
                return []
        }

        return HTTPCookie.cookies(withResponseHeaderFields: headers, for: loginURL)
    }
}
