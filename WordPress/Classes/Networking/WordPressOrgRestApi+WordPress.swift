import Foundation
import WordPressShared
import WordPressKit

private func apiBase(blog: Blog) -> URL? {
    guard blog.account == nil else {
        assertionFailure(".com support has not been implemented yet")
        return nil
    }
    return try? blog.url(withPath: "wp-json/")?.asURL()
}

extension WordPressOrgRestApi {
    @objc
    convenience init?(
        blog: Blog,
        userAgent: String = WPUserAgent.wordPress(),
        wordPressComApiURL: URL = AppEnvironment.current.wordPressComApiBase
    ) {
        if let dotComID = blog.dotComID?.uint64Value,
           let token = blog.account?.authToken,
           token.count > 0 {
            self.init(
                dotComSiteID: dotComID,
                bearerToken: token,
                userAgent: userAgent,
                apiURL: wordPressComApiURL
            )
        } else if let apiBase = apiBase(blog: blog),
                  let loginURL = try? blog.loginUrl().asURL(),
                  let adminURL = try? blog.adminUrl(withPath: "").asURL(),
                  let username = blog.username,
                  let password = blog.password {
            self.init(
                selfHostedSiteWPJSONURL: apiBase,
                credential: .init(
                    loginURL: loginURL,
                    username: username,
                    password: password,
                    adminURL: adminURL
                ),
                userAgent: userAgent
            )
        } else {
            return nil
        }
    }
}
