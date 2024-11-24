import Foundation
import WordPressAPI
import Network

struct WordPressSite {
    enum SiteType {
        case dotCom(authToken: String)
        case selfHosted(username: String, authToken: String)
    }

    let baseUrl: URL
    let type: WordPressSite.SiteType

    init(baseUrl: ParsedUrl, type: WordPressSite.SiteType) {
        self.baseUrl = baseUrl.asURL()
        self.type = type
    }

    init(blog: Blog) throws {
        let url = try ParsedUrl.parse(input: blog.getUrlString())
        if let account = blog.account {
            self.init(baseUrl: url, type: .dotCom(authToken: account.authToken))
        } else {
            self.init(baseUrl: url, type: .selfHosted(
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

    init(site: WordPressSite) {
        // `site.barUrl` is a legal HTTP URL, which should be convertable to the `ParsedUrl` type.
        let parsedUrl: ParsedUrl
        do {
            parsedUrl = try ParsedUrl.parse(input: site.baseUrl.absoluteString)
        } catch {
            fatalError("Failed to cast URL (\(site.baseUrl.absoluteString)) to ParsedUrl: \(error)")
        }

        // Currently, the app supports both account passwords and application passwords.
        // When a site is initially signed in with an account password, WordPress login cookies are stored
        // in `URLSession.shared`. After switching the site to application password authentication,
        // the stored cookies may interfere with application-password authentication, resulting in 401
        // errors from the REST API.
        //
        // To avoid this issue, we'll use an ephemeral URLSession for now (which stores cookies in memory
        // rather than using the shared one on disk).
        let session = URLSession(configuration: .ephemeral)

        switch site.type {
        case let .dotCom(authToken):
            let api = WordPressAPI(urlSession: session, baseUrl: parsedUrl, authenticationStategy: .authorizationHeader(token: authToken))
            self.init(api: api, rootUrl: parsedUrl)
        case .selfHosted(let username, let authToken):
            let api = WordPressAPI.init(urlSession: session, baseUrl: parsedUrl, authenticationStategy: .init(username: username, password: authToken))
            self.init(api: api, rootUrl: parsedUrl)
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
