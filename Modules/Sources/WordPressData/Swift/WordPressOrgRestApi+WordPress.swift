import Foundation
import WordPressShared
import WordPressKit

private func apiBase(blog: Blog) -> URL? {
    guard blog.account == nil else {
        assertionFailure(".com support has not been implemented yet")
        return nil
    }

    // Prefer the REST root observed during discovery over one derived from the raw
    // `xmlrpc` string, which an older app version could have persisted as http for an
    // https site (GHSA-qxpr-7v78-mh5g). See `Blog.selfHostedRestApiRootURL`.
    return blog.selfHostedRestApiRootURL
}

extension WordPressOrgRestApi {
    @objc
    public convenience init?(blog: Blog) {
        self.init(
            blog: blog,
            userAgent: WPUserAgent.wordPress(),
            wordPressComApiURL: WordPressComRestApi.apiBaseURL
        )
    }

    convenience init?(
        blog: Blog,
        userAgent: String = WPUserAgent.wordPress(),
        wordPressComApiURL: URL = WordPressComRestApi.apiBaseURL
    ) {
        if let dotComID = blog.dotComID?.uint64Value,
           let token = blog.account?.authToken,
           !token.isEmpty {
            self.init(
                dotComSiteID: dotComID,
                bearerToken: token,
                userAgent: userAgent,
                apiURL: wordPressComApiURL
            )
        } else if let apiBase = apiBase(blog: blog),
                  let username = blog.username {
            let credential: WordPressOrgRestApi.SelfHostedSiteCredential
            if let appPassword = try? blog.getApplicationToken() {
                credential = .applicationPassword(username: username, password: .init(appPassword))
            } else if let loginURL = blog.loginURL,
                      let adminURL = blog.makeAdminURL(),
                      let password = blog.password {
                credential = .accountPassword(loginURL: loginURL, username: username, password: .init(password), adminURL: adminURL)
            } else {
                return nil
            }
            self.init(
                selfHostedSiteWPJSONURL: apiBase,
                credential: credential,
                userAgent: userAgent
            )
        } else {
            return nil
        }
    }
}
