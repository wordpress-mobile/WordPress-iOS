import Foundation

public class PluginServiceRemote: ServiceRemoteWordPressComREST {
    public enum ResponseError: Error {
        case decodingFailure
        case invalidInputError
        case unauthorized
        case unknownError
    }

    public func getFeaturedPlugins(success: @escaping ([PluginDirectoryEntry]) -> Void, failure: @escaping (Error) -> Void) {
        let endpoint = "wpcom/v2/plugins/featured"

        wordPressComRestApi.GET(endpoint, parameters: nil, success: { (responseObject, httpResponse) in
            guard let response = responseObject as? [[String: AnyObject]] else {
                failure(ResponseError.decodingFailure)
                return
            }

            do {
                let pluginEntries = try response.map { try PluginDirectoryEntry(responseObject: $0) }
                success(pluginEntries)
            } catch {
                failure(ResponseError.decodingFailure)
            }
        }, failure: { (error, httpResponse) in
            DDLogError("[PluginServiceRemoteError] Error fetching featured plugins: \(error)")
            failure(error)
        })
    }


    public func getPlugins(siteID: Int, success: @escaping (SitePlugins) -> Void, failure: @escaping (Error) -> Void) {
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
                success(SitePlugins(plugins: pluginStates, capabilities: capabilities))
            } catch {
                failure(self.errorFromResponse(response))
            }
        }, failure: { (error, httpResponse) in
            DDLogError("[PluginServiceRemoteError] Error fetching site plugins: \(error)")
            failure(error)
        })
    }

    public func updatePlugin(pluginID: String, siteID: Int, success: @escaping (PluginState) -> Void, failure: @escaping (Error) -> Void) {
        guard let escapedPluginID = encoded(pluginID: pluginID) else {
            return
        }
        let endpoint = "sites/\(siteID)/plugins/\(escapedPluginID)/update"
        let path = self.path(forEndpoint: endpoint, withVersion: ._1_2)!
        let parameters = [String: AnyObject]()

        wordPressComRestApi.POST(
            path,
            parameters: parameters,
            success: { (responseObject, _)  in
                guard let response = responseObject as? [String: AnyObject] else {
                    failure(ResponseError.decodingFailure)
                    return
                }
                do {
                    let pluginState = try self.pluginState(response: response)
                    success(pluginState)
                } catch {
                    failure(self.errorFromResponse(response))
                }
        },
            failure: { (error, _) in
                DDLogError("[PluginServiceRemoteError] Error updating plugin: \(error)")
                failure(error)
        })
    }

    public func activatePlugin(pluginID: String, siteID: Int, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let parameters = [
            "active": "true"
            ] as [String: AnyObject]
        modifyPlugin(parameters: parameters, pluginID: pluginID, siteID: siteID, success: success, failure: failure)
    }

     public func deactivatePlugin(pluginID: String, siteID: Int, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let parameters = [
            "active": "false"
            ] as [String: AnyObject]
        modifyPlugin(parameters: parameters, pluginID: pluginID, siteID: siteID, success: success, failure: failure)
    }

     public func enableAutoupdates(pluginID: String, siteID: Int, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let parameters = [
            "autoupdate": "true"
            ] as [String: AnyObject]
        modifyPlugin(parameters: parameters, pluginID: pluginID, siteID: siteID, success: success, failure: failure)
    }

     public func disableAutoupdates(pluginID: String, siteID: Int, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let parameters = [
            "autoupdate": "false"
            ] as [String: AnyObject]
        modifyPlugin(parameters: parameters, pluginID: pluginID, siteID: siteID, success: success, failure: failure)
    }

    public func activateAndEnableAutoupdated(pluginID: String, siteID: Int, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let parameters = [
            "active": "true",
            "autoupdate": "true"
            ] as [String: AnyObject]
        modifyPlugin(parameters: parameters, pluginID: pluginID, siteID: siteID, success: success, failure: failure)
    }

    public func install(pluginSlug: String, siteID: Int, success: @escaping (PluginState) -> Void, failure: @escaping (Error) -> Void) {
        let endpoint = "sites/\(siteID)/plugins/\(pluginSlug)/install"
        let path = self.path(forEndpoint: endpoint, withVersion: ._1_2)!

        wordPressComRestApi.POST(
            path,
            parameters: nil,
            success: { responseObject,_  in
                guard let response = responseObject as? [String: AnyObject] else {
                    failure(ResponseError.decodingFailure)
                    return
                }
                do {
                    let pluginState = try self.pluginState(response: response)
                    success(pluginState)
                } catch {
                    failure(self.errorFromResponse(response))
                }
            }, failure: { (error, _) in
                DDLogError("[PluginServiceRemoteError] Error installing plugin: \(error)")
                failure(error)
            }
        )
    }

     public func remove(pluginID: String, siteID: Int, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        guard let escapedPluginID = encoded(pluginID: pluginID) else {
            return
        }
        let endpoint = "sites/\(siteID)/plugins/\(escapedPluginID)/delete"
        let path = self.path(forEndpoint: endpoint, withVersion: ._1_2)!

        wordPressComRestApi.POST(
            path,
            parameters: nil,
            success: { _,_  in
                success()
            }, failure: { (error, _) in
                DDLogError("[PluginServiceRemoteError] Error removing plugin: \(error)")
                failure(error)
            }
        )
    }

    private func modifyPlugin(parameters: [String: AnyObject], pluginID: String, siteID: Int, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        guard let escapedPluginID = encoded(pluginID: pluginID) else {
            return
        }
        let endpoint = "sites/\(siteID)/plugins/\(escapedPluginID)"
        let path = self.path(forEndpoint: endpoint, withVersion: ._1_2)!

        wordPressComRestApi.POST(
            path,
            parameters: parameters,
            success: { _,_  in
                success()
            },
            failure: { (error, _) in
                DDLogError("[PluginServiceRemoteError] Error modifying plugin: \(error)")
                failure(error)
            })
    }
}

fileprivate extension PluginServiceRemote {
    func encoded(pluginID: String) -> String? {
        let allowedCharacters = CharacterSet.urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))
        guard let escapedPluginID = pluginID.addingPercentEncoding(withAllowedCharacters: allowedCharacters) else {
            assertionFailure("Can't escape plugin ID: \(pluginID)")
            return nil
        }
        return escapedPluginID
    }

    func pluginStates(response: [String: AnyObject]) throws -> [PluginState] {
        guard let plugins = response["plugins"] as? [[String: AnyObject]] else {
            throw ResponseError.decodingFailure
        }

        return try plugins.map { (plugin) -> PluginState in
            return try pluginState(response: plugin)
        }
    }

    func pluginState(response: [String: AnyObject]) throws -> PluginState {
        guard let id = response["name"] as? String,
            let slug = response["slug"] as? String,
            let active = response["active"] as? Bool,
            let autoupdate = response["autoupdate"] as? Bool,
            let name = response["display_name"] as? String,
            let author = response["author"] as? String else {
                throw ResponseError.decodingFailure
        }


        let version = (response["version"] as? String)?.nonEmptyString()
        let url = (response["plugin_url"] as? String).flatMap(URL.init(string:))
        let availableUpdate = (response["update"] as? [String: String])?["new_version"]
        let updateState: PluginState.UpdateState = availableUpdate.map({ .available($0) }) ?? .updated

        let actions = response["action_links"] as? [String: String]
        let settingsURL = (actions?["Settings"]).flatMap(URL.init(string:))

        return PluginState(id: id,
                           slug: slug,
                           active: active,
                           name: name,
                           author: author,
                           version: version,
                           updateState: updateState,
                           autoupdate: autoupdate,
                           automanaged: false,
                           url: url,
                           settingsURL: settingsURL)

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
