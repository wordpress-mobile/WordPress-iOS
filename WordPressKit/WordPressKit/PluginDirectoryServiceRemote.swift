import Foundation
import Alamofire

public struct PluginDirectoryServiceRemote {
    public enum Error: Swift.Error {
        case pluginNotFound
    }

    let baseURL = URL(string: "https://api.wordpress.org/plugins/info/1.0/")!
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd h:mma z"
        return formatter
    }()

    public init() {
    }

    public func getPluginInformation(slug: String, completion: @escaping (Result<PluginDirectoryEntry>) -> Void) {
        do {
            let request = try pluginInformationURLRequest(forSlug: slug)

            Alamofire
                .request(request)
                .validate()
                .validateNotNullJSON()
                .responseData(completionHandler: { (response) in
                    let result = response.result
                        .flatMap({ return try self.pluginEntry(fromData: $0) })
                    completion(result)
                })
        } catch {
            completion(.failure(error))
        }
    }
}

private extension DataRequest {
    // api.wordpress.org has an odd way of responding to plugin info requests for
    // plugins not in the directory: it will return `null` with an HTTP 200 OK.
    // This adds a custom validate step to turn that into a `.pluginNotFound` error.
    func validateNotNullJSON() -> Self {
        return validate({ (_, response, data) -> Request.ValidationResult in
            if response.statusCode == 200,
                let data = data,
                data.count == 4,
                String(data: data, encoding: .utf8) == "null" {
                return .failure(PluginDirectoryServiceRemote.Error.pluginNotFound)
            } else {
                return .success
            }
        })
    }
}

extension PluginDirectoryServiceRemote {
    func pluginInformationURLRequest(forSlug slug: String) throws -> URLRequest {
        let url = baseURL
            .appendingPathComponent(slug)
            .appendingPathExtension("json")
        let request = URLRequest(url: url)
        let encodedRequest = try URLEncoding.default.encode(request, with: ["fields": "icons"])
        return encodedRequest
    }

    func pluginEntry(fromData data: Data) throws -> PluginDirectoryEntry {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(PluginDirectoryServiceRemote.dateFormatter)
        return try decoder.decode(PluginDirectoryEntry.self, from: data)
    }
}
