import Foundation

public class PluginServiceRemote: ServiceRemoteWordPressComREST {
    public enum ResponseError: Error {
        case decodingFailure
        case invalidInputError
        case unauthorized
        case unknownError
    }

    public func getPlugins(siteID: Int, success: @escaping ([PluginState], SitePluginCapabilities) -> Void, failure: @escaping (Error) -> Void) {
        let endpoint = "sites/\(siteID)/plugins"
        let path = self.path(forEndpoint: endpoint, withVersion: ._1_2)!
        let parameters = [String: AnyObject]()

        wordPressComRestApi.GET(path, parameters: parameters, success: { (responseObject, httpResponse) in
            guard let response = responseObject as? [String: AnyObject] else {
                failure(ResponseError.decodingFailure)
                return
            }
            do {
                let pluginStates = try self.pluginStates(response: response)
                let capabilities = try self.pluginCapabilities(response: response)
                success(pluginStates, capabilities)
            } catch {
                failure(self.errorFromResponse(response))
            }
        }, failure: { (error, httpResponse) in
            failure(error)
        })
    }
}

fileprivate extension PluginServiceRemote {
    func pluginStates(response: [String: AnyObject]) throws -> [PluginState] {
        guard let plugins = response["plugins"] as? [[String: AnyObject]] else {
            throw ResponseError.decodingFailure
        }

        return try plugins.map { (plugin) -> PluginState in
            return try pluginState(response: plugin)
        }
    }

    func pluginState(response: [String: AnyObject]) throws -> PluginState {
        guard let slug = response["slug"] as? String,
            let active = response["active"] as? Bool,
            let autoupdate = response["autoupdate"] as? Bool,
            let name = response["display_name"] as? String else {
                throw ResponseError.decodingFailure
        }
        let version = response["version"] as? String
        return PluginState(slug: slug,
                           active: active,
                           name: name,
                           version: version,
                           autoupdate: autoupdate)

    }

    func pluginCapabilities(response: [String: AnyObject]) throws -> SitePluginCapabilities {
        guard let capabilities = response["file_mod_capabilities"] as? [String: AnyObject],
            let modify = capabilities["modify_files"] as? Bool,
            let autoupdate = capabilities["autoupdate_files"] as? Bool else {
                throw ResponseError.decodingFailure
        }
        return SitePluginCapabilities(modify: modify, autoupdate: autoupdate)
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
