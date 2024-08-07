import Foundation
import WordPressAPI
import Network

struct WordPressSite {
    enum SiteType {
        case dotCom(emailAddress: String, authToken: String)
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
            return WordPressSite(baseUrl: url, type: .dotCom(
                emailAddress: account.email,
                authToken: account.authToken
            ))
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

    private let underlyingConnection: NWConnection
    private let dispatchQueue = DispatchQueue(label: "wordpress-client")
    var reachabilityStatus: ReachabilityStatus = .unknown

    init(api: WordPressAPI, rootUrl: ParsedUrl) {
        self.api = api
        self.rootUrl = rootUrl.url()

        let endpoint = NWEndpoint.url(URL(string: rootUrl.url())!)

        self.underlyingConnection = NWConnection(to: endpoint, using: NWParameters())
        self.underlyingConnection.pathUpdateHandler = { [weak self] path in
            guard let self else { return }

            debugPrint("reachability is now \(path)")
            Task {
                switch path.status {
                case .requiresConnection: await self.setReachabilityStatus(to: .unknown)
                case .satisfied: await self.setReachabilityStatus(to: .available(path: path))
                case .unsatisfied: await self.setReachabilityStatus(to: .unavailable(
                    reason: path.unsatisfiedReason)
                )
                @unknown default:
                    assertionFailure("Unknown status: \(path.status)")
                    DDLogError("Unknown status: \(path.status)")
                    await self.setReachabilityStatus(to: .unknown)
                }
            }
        }
        self.underlyingConnection.start(queue: self.dispatchQueue)
    }

    private func setReachabilityStatus(to newValue: ReachabilityStatus) {
        self.reachabilityStatus = newValue
    }

    static func `for`(site: WordPressSite, in session: URLSession) throws -> WordPressClient {
        let parsedUrl = try ParsedUrl.parse(input: site.baseUrl)

        switch site.type {
        case .dotCom(let emailAddress, let authToken):
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

extension PluginWpOrgDirectorySlug: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String

    public init(stringLiteral: String) {
        self.init(slug: stringLiteral)
    }
}
