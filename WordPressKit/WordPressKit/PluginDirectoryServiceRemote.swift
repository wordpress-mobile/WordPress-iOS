import Foundation
import Alamofire

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

    public var hashValue: Int {
        return slug.hashValue
    }

    public static func ==(lhs: PluginDirectoryFeedType, rhs: PluginDirectoryFeedType) -> Bool {
        return lhs.slug == rhs.slug
    }

}

public struct PluginDirectoryGetInformationEndpoint: Endpoint {
    public enum Error: Swift.Error {
        case pluginNotFound
    }

    let slug: String
    public init(slug: String) {
        self.slug = slug
    }

    public func buildRequest() throws -> URLRequest {
        let url = PluginDirectoryRemoteConstants.getInformationEndpoint
            .appendingPathComponent(slug)
            .appendingPathExtension("json")
        let request = URLRequest(url: url)
        let encodedRequest = try URLEncoding.default.encode(request, with: ["fields": "icons,banners"])
        return encodedRequest
    }

    public func parseResponse(data: Data) throws -> PluginDirectoryEntry {
        return try PluginDirectoryRemoteConstants.jsonDecoder.decode(PluginDirectoryEntry.self, from: data)
    }

    public func validate(request: URLRequest?, response: HTTPURLResponse, data: Data?) throws {
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

public struct PluginDirectoryFeedEndpoint: Endpoint {
    public enum Error: Swift.Error {
        case genericError
    }

    let feedType: PluginDirectoryFeedType
    let pageNumber: Int

    public func buildRequest() throws -> URLRequest {
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

        let request = URLRequest(url: PluginDirectoryRemoteConstants.feedEndpoint)
        let encodedRequest = try URLEncoding.default.encode(request, with: parameters)

        return encodedRequest
    }

    public func parseResponse(data: Data) throws -> PluginDirectoryFeedPage {
        return try PluginDirectoryRemoteConstants.jsonDecoder.decode(PluginDirectoryFeedPage.self, from: data)
    }

   public func validate(request: URLRequest?, response: HTTPURLResponse, data: Data?) throws {
        if response.statusCode != 200 { throw Error.genericError}
    }
}


public struct PluginDirectoryServiceRemote {

    public init() {}

    public func getPluginFeed(_ feedType: PluginDirectoryFeedType,
                              pageNumber: Int = 1,
                              completion: @escaping (Result<PluginDirectoryFeedPage>) -> Void) {
        PluginDirectoryFeedEndpoint(feedType: feedType, pageNumber: pageNumber).request(completion: completion)
    }

    public func getPluginInformation(slug: String, completion: @escaping (Result<PluginDirectoryEntry>) -> Void) {
        PluginDirectoryGetInformationEndpoint(slug: slug).request(completion: completion)
    }
}
