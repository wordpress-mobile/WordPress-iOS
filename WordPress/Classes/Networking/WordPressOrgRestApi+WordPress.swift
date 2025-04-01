import Foundation
import WordPressShared
import WordPressKit

private func apiBase(blog: Blog) -> URL? {
    guard blog.account == nil else {
        assertionFailure(".com support has not been implemented yet")
        return nil
    }

    guard let urlString = blog.url(withPath: "wp-json/") else {
        return nil
    }

    return URL(string: urlString)
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
           token.count > 0 {
            self.init(
                dotComSiteID: dotComID,
                bearerToken: token,
                userAgent: userAgent,
                apiURL: wordPressComApiURL
            )
        } else if let apiBase = apiBase(blog: blog),
                  let loginURL = URL(string: blog.loginUrl()),
                  let adminURL = URL(string: blog.adminUrl(withPath: "")),
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
