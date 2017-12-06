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
        let url = baseURL
            .appendingPathComponent(slug)
            .appendingPathExtension("json")
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            do {
                if let error = error {
                    throw error
                } else if let data = data {
                    success(try self.pluginEntry(fromData: data))
                } else {
                    throw Errors.noData
                }
            } catch {
                failure(error)
            }
        }
        task.resume()
    }
}

extension PluginDirectoryServiceRemote {
    func pluginEntry(fromData data: Data) throws -> PluginDirectoryEntry {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(PluginDirectoryServiceRemote.dateFormatter)
        return try decoder.decode(PluginDirectoryEntry.self, from: data)
    }
}
