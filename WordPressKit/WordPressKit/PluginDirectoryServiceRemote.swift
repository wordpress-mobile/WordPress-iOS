import Foundation

public struct PluginDirectoryServiceRemote {
    enum Errors: Error {
        case noData
    }

    let baseURL = URL(string: "https://api.wordpress.org/plugins/info/1.0/")!
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd h:mma z"
        return formatter
    }()

    public init() {
    }

    public func getPluginInformation(slug: String, success: @escaping (PluginDirectoryEntry) -> Void, failure: @escaping (Error) -> Void) {
        do {
            let url = try pluginInformationURL(forSlug: slug)
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                do {
                    if let error = error {
                        throw error
                    } else if let data = data {
                        let entry = try self.pluginEntry(fromData: data)
                        DispatchQueue.main.async {
                            success(entry)
                        }
                    } else {
                        throw Errors.noData
                    }
                } catch {
                    DispatchQueue.main.async {
                        failure(error)
                    }
                }
            }
            task.resume()
        } catch {
            failure(error)
        }
    }
}

extension PluginDirectoryServiceRemote {
    func pluginInformationURL(forSlug slug: String) throws -> URL {
        let endpoint = baseURL
            .appendingPathComponent(slug)
            .appendingPathExtension("json")
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "fields", value: "icons")
        ]
        return try components.asURL()
    }

    func pluginEntry(fromData data: Data) throws -> PluginDirectoryEntry {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(PluginDirectoryServiceRemote.dateFormatter)
        return try decoder.decode(PluginDirectoryEntry.self, from: data)
    }
}
