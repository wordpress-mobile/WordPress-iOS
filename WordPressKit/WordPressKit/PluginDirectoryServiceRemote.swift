import Foundation
import Alamofire

public struct PluginDirectoryGetInformationEndpoint: Endpoint {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "YYYY-MM-dd h:mma z"
        return formatter
    }()

    public enum Error: Swift.Error {
        case pluginNotFound
    }

    let slug: String
    public init(slug: String) {
        self.slug = slug
    }

    public func buildRequest() throws -> URLRequest {
        let baseURL = URL(string: "https://api.wordpress.org/plugins/info/1.0/")!

        let url = baseURL
            .appendingPathComponent(slug)
            .appendingPathExtension("json")
        let request = URLRequest(url: url)
        let encodedRequest = try URLEncoding.default.encode(request, with: ["fields": "icons,banners"])
        return encodedRequest
    }

    public func parseResponse(data: Data) throws -> PluginDirectoryEntry {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(PluginDirectoryGetInformationEndpoint.dateFormatter)
        return try decoder.decode(PluginDirectoryEntry.self, from: data)
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

public enum PluginDirectoryFeedType {
    case popular
    case newest
    case search(term: String)

    public var feedName: String {
        switch self {
        case .popular:
            return "popular"
        case .newest:
            return "newest"
        case .search(let term):
            return "search:\(term)"
        }
    }

}

public struct PluginDirectoryFeedEndpoint: Endpoint {
    private let pluginsPerPage = 50



    public enum Error: Swift.Error {
        case genericError
    }

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "YYYY-MM-dd h:mma z"
        return formatter
    }()

    let feedType: PluginDirectoryFeedType
    let pageNumber: Int

    public func buildRequest() throws -> URLRequest {
        // note that this _isn't_ the same URL as PluginDirectoryGetInformationEndpoint.
        let baseURL = URL(string: "https://api.wordpress.org/plugins/info/1.1/")!

        var parameters: [String: Any] = ["action": "query_plugins",
                                         "request[per_page]": pluginsPerPage,
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

        let request = URLRequest(url: baseURL)
        let encodedRequest = try URLEncoding.default.encode(request, with: parameters)

        return encodedRequest
    }

    public func parseResponse(data: Data) throws -> PluginDirectoryResponse {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(PluginDirectoryGetInformationEndpoint.dateFormatter)
        return try decoder.decode(PluginDirectoryResponse.self, from: data)
    }

   public func validate(request: URLRequest?, response: HTTPURLResponse, data: Data?) throws {
        if response.statusCode != 200 { throw Error.genericError}
    }
}


public struct PluginDirectoryServiceRemote {

    public init() {}

    public func getPluginFeed(_ feedType: PluginDirectoryFeedType,
                              pageNumber: Int = 1,
                              completion: @escaping (Result<PluginDirectoryResponse>) -> Void) {
        PluginDirectoryFeedEndpoint(feedType: feedType, pageNumber: pageNumber).request(completion: completion)
    }

    public func getPluginInformation(slug: String, completion: @escaping (Result<PluginDirectoryEntry>) -> Void) {
        PluginDirectoryGetInformationEndpoint(slug: slug).request(completion: completion)
    }
}
