
class SelfHostedPluginManagementClient: PluginManagementClient {
    private let remote: WordPressOrgRestApi

    required init?(with remote: WordPressOrgRestApi) {
        self.remote = remote
    }

    // MARK: - Get
    func getPlugins(success: @escaping (SitePlugins) -> Void, failure: @escaping (Error) -> Void) {
        remote.GET(path(), parameters: nil) { (result, _) in
            switch result {
                case .success(let responseObject):
                    guard let response = responseObject as? [[String: AnyObject]] else {
                        failure(PluginServiceRemote.ResponseError.decodingFailure)
                        return
                    }

                    let plugins = response.compactMap { (obj) -> PluginState? in
                        self.pluginState(with: obj)
                    }

                    let result = SitePlugins(plugins: plugins,
                                             capabilities: SitePluginCapabilities(modify: true, autoupdate: false))
                    success(result)

                case .failure(let error):
                    failure(error)
            }
        }
    }

    // MARK: - Activate / Deactivate
    func activatePlugin(pluginID: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let parameters = ["status": "active"] as [String: AnyObject]
        let path = self.path(with: pluginID)
        remote.request(method: .put, path: path, parameters: parameters) { (result, _) in
            switch result {
                case .success:
                    success()

                case .failure(let error):
                    failure(error)
            }
        }
    }

    func deactivatePlugin(pluginID: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let parameters = ["status": "inactive"] as [String: AnyObject]
        let path = self.path(with: pluginID)
        remote.request(method: .put, path: path, parameters: parameters) { (result, _) in
            switch result {
                case .success:
                    success()

                case .failure(let error):
                    failure(error)
            }
        }

    }

    // MARK: - Install / Uninstall
    func install(pluginSlug: String, success: @escaping (PluginState) -> Void, failure: @escaping (Error) -> Void) {
        let parameters = ["slug": pluginSlug] as [String: AnyObject]

        remote.request(method: .post, path: path(), parameters: parameters) { (result, _) in
            switch result {
                case .success(let responseObject):
                    guard let response = responseObject as? [String: AnyObject],
                          let plugin = self.pluginState(with: response) else {
                        failure(PluginServiceRemote.ResponseError.decodingFailure)
                        return
                    }

                    success(plugin)
                case .failure(let error):
                    failure(error)
            }
        }
    }

    func remove(pluginID: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let path = self.path(with: pluginID)

        remote.request(method: .delete, path: path, parameters: nil) { (result, _) in
            switch result {
                case .success:
                    success()

                case .failure(let error):
                    failure(error)
            }
        }
    }

    // MARK: - Private: Helpers
    private func path(with slug: String? = nil) -> String {
        var returnPath = "wp/v2/plugins/"

        if let slug = slug {
            returnPath = returnPath.appending(slug)
        }

        return returnPath
    }

    /// Converts an incoming dictionary response to a PluginState struct
    /// - Returns: Returns nil if the dictionary does not pass validation
    private func pluginState(with obj: [String: AnyObject]) -> PluginState? {
        guard
            let slug = obj["plugin"] as? String,
            // The slugs returned are in the form of XXX/YYY
            // The plugin store uses an ID that is just the first part of that
            // So pull that out for the ID
            let id = slug.components(separatedBy: "/").first,
            let active = obj["status"] as? String,
            let name = obj["name"] as? String,
            let author = obj["author"] as? String,
            let version = obj["version"] as? String
        else {
            return nil
        }

        let isActive = active == "active"

        // Find the URL
        let url = URL(string: (obj["plugin_uri"] as? String) ?? "")

        return PluginState(id: id,
                           slug: slug,
                           active: isActive,
                           name: name,
                           author: author,
                           version: version,
                           updateState: .updated, // API Doesn't support this yet
                           autoupdate: false, // API Doesn't support this yet
                           automanaged: false, // API Doesn't support this yet
                           url: url,
                           settingsURL: nil)
    }


    // MARK: - Unsupported
    func updatePlugin(pluginID: String, success: @escaping (PluginState) -> Void, failure: @escaping (Error) -> Void) {
        // NOOP - Not supported by the WP.org REST API
    }

    func enableAutoupdates(pluginID: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        // NOOP - Not supported by the WP.org REST API

        success()
    }

    func disableAutoupdates(pluginID: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        // NOOP - Not supported by the WP.org REST API

        success()
    }

    func activateAndEnableAutoupdates(pluginID: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        // Just activate since API does not support autoupdates yet
        activatePlugin(pluginID: pluginID, success: success, failure: failure)
    }
}
