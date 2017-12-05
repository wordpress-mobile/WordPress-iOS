import Foundation

public struct PluginDirectoryServiceRemote {
    enum Errors: Error {
        case decodingError
        case noData
    }

    let baseURL = URL(string: "https://api.wordpress.org/plugins/info/1.0/")!

    public func getPluginInformation(slug: String, success: @escaping (PluginDirectoryEntry) -> Void, failure: @escaping (Error) -> Void) {
        let url = baseURL
            .appendingPathComponent(slug)
            .appendingPathExtension("json")
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                failure(error)
            } else if let data = data {
                guard let plugin = try? JSONDecoder().decode(PluginDirectoryEntry.self, from: data) else {
                    failure(Errors.decodingError)
                    return
                }
                success(plugin)
            } else {
                failure(Errors.noData)
            }
        }
        task.resume()
    }
}
