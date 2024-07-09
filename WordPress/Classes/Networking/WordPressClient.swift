import Foundation
import WordPressAPI

struct WordPressSite {
    enum SiteType {
        case dotCom(emailAddress: String, authToken: String)
        case selfHosted(username: String, authToken: String)
    }

    let baseUrl: String
    let type: WordPressSite.SiteType
}

actor WordPressClient {

    private let api: WordPressAPI

    init(api: WordPressAPI) {
        self.api = api
    }

    static func `for`(site: WordPressSite, in session: URLSession) throws -> WordPressClient {
        let parsedUrl = try ParsedUrl.parse(input: site.baseUrl)

        switch site.type {
        case .dotCom(let emailAddress, let authToken):
            let api = WordPressAPI(urlSession: session, baseUrl: parsedUrl, authenticationStategy: .authorizationHeader(token: authToken))
            return WordPressClient(api: api)
        case .selfHosted(let username, let authToken):
            let api = WordPressAPI.init(urlSession: session, baseUrl: parsedUrl, authenticationStategy: .init(username: username, password: authToken))
            return WordPressClient(api: api)
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
