import Foundation
import Alamofire

public struct PluginDirectoryGetInformationEndpoint: Endpoint {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
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

public struct PluginDirectoryServiceRemote {
    public init() {}

    public func getPluginInformation(slug: String, completion: @escaping (Result<PluginDirectoryEntry>) -> Void) {
        PluginDirectoryGetInformationEndpoint(slug: slug).request(completion: completion)
    }
}
