import Foundation

public class PluginServiceRemote: ServiceRemoteWordPressComREST {
    public enum ResponseError: Error {
        case decodingFailure
        case invalidInputError
        case unauthorized
        case unknownError
    }

    public func getPlugins(siteID: Int, success: @escaping ([PluginState]) -> Void, failure: @escaping (Error) -> Void) {
        let endpoint = "sites/\(siteID)/plugins"
        let path = self.path(forEndpoint: endpoint, with: .version_1_1)!
        let parameters = [String: AnyObject]()

        wordPressComRestApi.GET(path, parameters: parameters, success: { (responseObject, httpResponse) in
            guard let response = responseObject as? [String: AnyObject] else {
                failure(ResponseError.decodingFailure)
                return
            }
            guard let plugins = response["plugins"] as? [[String: AnyObject]],
                let pluginStates = try? self.pluginStatesFromResponse(plugins) else {
                    failure(self.errorFromResponse(response))
                    return
            }
            success(pluginStates)
        }, failure: { (error, httpResponse) in
            failure(error)
        })
    }
}

fileprivate extension PluginServiceRemote {
    func pluginStatesFromResponse(_ plugins: [[String: AnyObject]]) throws -> [PluginState] {
        return try plugins.map { (plugin) -> PluginState in
            return try pluginStateFromResponse(plugin)
        }
    }

    func pluginStateFromResponse(_ plugin: [String: AnyObject]) throws -> PluginState {
        guard let id = plugin["id"] as? String,
        let slug = plugin["slug"] as? String,
        let active = plugin["active"] as? Bool,
        let autoupdate = plugin["autoupdate"] as? Bool,
            let name = plugin["name"] as? String else {
                throw ResponseError.decodingFailure
        }
        let version = plugin["version"] as? String
        return PluginState(id: id,
                           slug: slug,
                           active: active,
                           name: name,
                           version: version,
                           autoupdate: autoupdate)

    }

    func errorFromResponse(_ response: [String: AnyObject]) -> ResponseError {
        guard let code = response["error"] as? String else {
                return .decodingFailure
        }
        switch code {
        case "unauthorized":
            return .unauthorized
        default:
            return .unknownError
        }
    }
}
