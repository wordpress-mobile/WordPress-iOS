import Foundation

private struct PluginDirectoryRemoteConstants {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "YYYY-MM-dd h:mma z"
        return formatter
    }()

    static let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(PluginDirectoryRemoteConstants.dateFormatter)
        return decoder
    }()

    static let pluginsPerPage = 50

    static let getInformationEndpoint = URL(string: "https://api.wordpress.org/plugins/info/1.0/")!
    static let feedEndpoint = URL(string: "https://api.wordpress.org/plugins/info/1.1/")!
    // note that this _isn't_ the same URL as PluginDirectoryGetInformationEndpoint.
}

public enum PluginDirectoryFeedType: Hashable {
    case popular
    case newest
    case search(term: String)

    public var slug: String {
        switch self {
        case .popular:
            return "popular"
        case .newest:
            return "newest"
        case .search(let term):
            return "search:\(term)"
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(slug)
    }

    public static func ==(lhs: PluginDirectoryFeedType, rhs: PluginDirectoryFeedType) -> Bool {
        return lhs.slug == rhs.slug
    }
}

public struct PluginDirectoryGetInformationEndpoint {
    public enum Error: Swift.Error {
        case pluginNotFound
    }

    let slug: String
    public init(slug: String) {
        self.slug = slug
    }

    func buildRequest() throws -> URLRequest {
        try HTTPRequestBuilder(url: PluginDirectoryRemoteConstants.getInformationEndpoint)
            .appendURLString("\(slug).json")
            .query(name: "fields", value: "icons,banners")
            .build()
    }

    func parseResponse(data: Data) throws -> PluginDirectoryEntry {
        return try PluginDirectoryRemoteConstants.jsonDecoder.decode(PluginDirectoryEntry.self, from: data)
    }

    func validate(response: HTTPURLResponse, data: Data?) throws {
        // api.wordpress.org has an odd way of responding to plugin info requests for
        // plugins not in the directory: it will return `null` with an HTTP 200 OK.
        // This turns that case into a `.pluginNotFound` error.
        if response.statusCode == 200,
            let data = data,
            data.count == 4,
            String(data: data, encoding: .utf8) == "null" {
                throw Error.pluginNotFound
        }
    }
}

public struct PluginDirectoryFeedEndpoint {
    public enum Error: Swift.Error {
        case genericError
    }

    let feedType: PluginDirectoryFeedType
    let pageNumber: Int

    init(feedType: PluginDirectoryFeedType) {
        self.feedType = feedType
        self.pageNumber = 1
    }

    func buildRequest() throws -> URLRequest {
        var parameters: [String: Any] = ["action": "query_plugins",
                                         "request[per_page]": PluginDirectoryRemoteConstants.pluginsPerPage,
                                         "request[fields][icons]": 1,
                                         "request[fields][banners]": 1,
                                         "request[fields][sections]": 0,
                                         "request[page]": pageNumber]
        switch feedType {
        case .popular:
            parameters["request[browse]"] = "popular"
        case .newest:
            parameters["request[browse]"] = "new"
        case .search(let term):
            parameters["request[search]"] = term

        }

        return try HTTPRequestBuilder(url: PluginDirectoryRemoteConstants.feedEndpoint)
            .query(parameters)
            .build()
    }

    func parseResponse(data: Data) throws -> PluginDirectoryFeedPage {
        return try PluginDirectoryRemoteConstants.jsonDecoder.decode(PluginDirectoryFeedPage.self, from: data)
    }

    func validate(response: HTTPURLResponse, data: Data?) throws {
        if response.statusCode != 200 { throw Error.genericError}
    }
}

public struct PluginDirectoryServiceRemote {

    public init() {}

    public func getPluginFeed(_ feedType: PluginDirectoryFeedType, pageNumber: Int = 1) async throws -> PluginDirectoryFeedPage {
        let endpoint = PluginDirectoryFeedEndpoint(feedType: feedType)
        let (data, response) = try await URLSession.shared.data(for: endpoint.buildRequest())
        let httpResponse = response as! HTTPURLResponse
        try endpoint.validate(response: httpResponse, data: data)
        return try endpoint.parseResponse(data: data)
    }

    public func getPluginInformation(slug: String) async throws -> PluginDirectoryEntry {
        let endpoint = PluginDirectoryGetInformationEndpoint(slug: slug)
        let (data, response) = try await URLSession.shared.data(for: endpoint.buildRequest())
        let httpResponse = response as! HTTPURLResponse
        try endpoint.validate(response: httpResponse, data: data)
        return try endpoint.parseResponse(data: data)
    }
}
