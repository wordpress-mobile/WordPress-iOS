import Foundation
import WordPressAPI
import Network

struct WordPressSite {
    enum SiteType {
        case dotCom(authToken: String)
        case selfHosted(username: String, authToken: String)
    }

    let baseUrl: String
    let type: WordPressSite.SiteType

    init(baseUrl: ParsedUrl, type: WordPressSite.SiteType) {
        self.baseUrl = baseUrl.url()
        self.type = type
    }

    static func from(blog: Blog) throws -> WordPressSite {
        let url = try ParsedUrl.parse(input: blog.getUrlString())
        if let account = blog.account {
            return WordPressSite(baseUrl: url, type: .dotCom(authToken: account.authToken))
        } else {
            return WordPressSite(baseUrl: url, type: .selfHosted(
                username: try blog.getUsername(),
                authToken: try blog.getApplicationToken())
            )
        }
    }
}

actor WordPressClient {

    enum ReachabilityStatus {
        case unknown
        case available(path: NWPath)
        case unavailable(reason: NWPath.UnsatisfiedReason)
    }

    let api: WordPressAPI
    private let rootUrl: String

    init(api: WordPressAPI, rootUrl: ParsedUrl) {
        self.api = api
        self.rootUrl = rootUrl.url()
    }

    static func `for`(site: WordPressSite) throws -> WordPressClient {
        let parsedUrl = try ParsedUrl.parse(input: site.baseUrl)

        // At the moment, the app supports account password and application password.
        // When a site is initially signed in with account password, WordPress login cookies are stored
        // in `URLSession.shared`. After switching the site to application password authentication,
        // the store cookies may interfere with application-password authentication, which results in 401
        // errors from REST API.
        //
        // To avoid the above issue, we'll use ephemeral URLSession for now (which stores cookies in memory
        // rather than using the shared one on disk).
        let session = URLSession(configuration: .ephemeral)

        switch site.type {
        case let .dotCom(authToken):
            let api = WordPressAPI(urlSession: session, baseUrl: parsedUrl, authenticationStategy: .authorizationHeader(token: authToken))
            return WordPressClient(api: api, rootUrl: parsedUrl)
        case .selfHosted(let username, let authToken):
            let api = WordPressAPI.init(urlSession: session, baseUrl: parsedUrl, authenticationStategy: .init(username: username, password: authToken))
            return WordPressClient(api: api, rootUrl: parsedUrl)
        }
    }

    func installJetpack() async throws -> PluginWithEditContext {
        try await self.api.plugins.create(params: PluginCreateParams(
            slug: "InstallJetpack",
            status: .active
        ))
    }
}

extension PluginWpOrgDirectorySlug: @retroactive ExpressibleByStringLiteral {
    public typealias StringLiteralType = String

    public init(stringLiteral: String) {
        self.init(slug: stringLiteral)
    }
}
