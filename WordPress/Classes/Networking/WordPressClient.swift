import Foundation
import WordPressAPI
import WordPressCore
import WordPressShared

enum WordPressSite {
    case dotCom(authToken: String)
    case selfHosted(apiRootURL: ParsedUrl, username: String, authToken: String)

    init(blog: Blog) throws {
        if let account = blog.account {
            let authToken = try account.authToken ?? WPAccount.token(forUsername: account.username)
            self = .dotCom(authToken: authToken)
        } else {
            let url = try blog.restApiRootURL ?? blog.getUrl().appending(path: "wp-json").absoluteString
            let apiRootURL = try ParsedUrl.parse(input: url)
            self = .selfHosted(apiRootURL: apiRootURL, username: try blog.getUsername(), authToken: try blog.getApplicationToken())
        }
    }
}

extension WordPressClient {

    init(site: WordPressSite) {
        // Currently, the app supports both account passwords and application passwords.
        // When a site is initially signed in with an account password, WordPress login cookies are stored
        // in `URLSession.shared`. After switching the site to application password authentication,
        // the stored cookies may interfere with application-password authentication, resulting in 401
        // errors from the REST API.
        //
        // To avoid this issue, we'll use an ephemeral URLSession for now (which stores cookies in memory
        // rather than using the shared one on disk).
        let session = URLSession(configuration: .ephemeral)

        switch site {
        case let .dotCom(authToken):
            let apiRootURL = try! ParsedUrl.parse(input: "https://public-api.wordpress.com")
            let api = WordPressAPI(urlSession: session, apiRootUrl: apiRootURL, authenticationStategy: .authorizationHeader(token: authToken))
            self.init(api: api, rootUrl: apiRootURL)
        case let .selfHosted(apiRootURL, username, authToken):
            let api = WordPressAPI(urlSession: session, apiRootUrl: apiRootURL, authenticationStategy: .init(username: username, password: authToken))
            self.init(api: api, rootUrl: apiRootURL)
        }
    }

    func installJetpack() async throws -> PluginWithEditContext {
        try await self.api.plugins.create(params: PluginCreateParams(
            slug: "InstallJetpack",
            status: .active
        )).data
    }
}

extension PluginWpOrgDirectorySlug: @retroactive ExpressibleByStringLiteral {
    public typealias StringLiteralType = String

    public init(stringLiteral: String) {
        self.init(slug: stringLiteral)
    }
}
