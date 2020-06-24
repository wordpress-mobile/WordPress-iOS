import Foundation
import WordPressKit

private func makeAuthenticator(blog: Blog) -> Authenticator? {
    return blog.account != nil
        ? makeTokenAuthenticator(blog: blog)
        : makeCookieNonceAuthenticator(blog: blog)
}

private func makeTokenAuthenticator(blog: Blog) -> Authenticator? {
    guard let token = blog.authToken else {
        DDLogError("Failed to initialize a .com API client with blog: \(blog)")
        return nil
    }
    return TokenAuthenticator(token: token)
}

private func makeCookieNonceAuthenticator(blog: Blog) -> Authenticator? {
    guard let loginURL = try? blog.loginUrl().asURL(),
        let adminURL = try? blog.adminUrl(withPath: "").asURL(),
        let username = blog.username,
        let password = blog.password,
        let version = blog.version as String? else {
        DDLogError("Failed to initialize a .org API client with blog: \(blog)")
        return nil
    }

    return CookieNonceAuthenticator(username: username, password: password, loginURL: loginURL, adminURL: adminURL, version: version)
}

private func apiBase(blog: Blog) -> URL? {
    precondition(blog.account == nil, ".com support has not been implemented yet")
    return try? blog.url(withPath: "wp-json/").asURL()
}

extension WordPressOrgRestApi {
    @objc public convenience init?(blog: Blog) {
        guard let apiBase = apiBase(blog: blog),
            let authenticator = makeAuthenticator(blog: blog) else {
            return nil
        }
        self.init(
            apiBase: apiBase,
            authenticator: authenticator,
            userAgent: WPUserAgent.wordPress()
        )
    }
}
