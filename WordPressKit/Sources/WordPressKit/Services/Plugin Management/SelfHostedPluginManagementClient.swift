public class SelfHostedPluginManagementClient: PluginManagementClient {
    private let remote: WordPressOrgRestApi

    public required init?(with remote: WordPressOrgRestApi) {
        self.remote = remote
    }

    // MARK: - Get
    public func getPlugins(success: @escaping (SitePlugins) -> Void, failure: @escaping (Error) -> Void) {
        Task { @MainActor in
            await remote.get(path: path(), type: [PluginStateResponse].self)
                .mapError { error -> Error in
                    if case let .unparsableResponse(_, _, underlyingError) = error, underlyingError is DecodingError {
                        return PluginServiceRemote.ResponseError.decodingFailure
                    }
                    return error
                }
                .map {
                    SitePlugins(
                        plugins: $0.compactMap { self.pluginState(with: $0) },
                        capabilities: SitePluginCapabilities(modify: true, autoupdate: false)
                    )
                }
                .execute(onSuccess: success, onFailure: failure)

        }
    }

    // MARK: - Activate / Deactivate
    public func activatePlugin(pluginID: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let parameters = ["status": "active"]
        let path = self.path(with: pluginID)
        Task { @MainActor in
            await remote.perform(.put, path: path, parameters: parameters, type: AnyResponse.self)
                .map { _ in }
                .execute(onSuccess: success, onFailure: failure)

        }
    }

    public func deactivatePlugin(pluginID: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let parameters = ["status": "inactive"]
        let path = self.path(with: pluginID)
        Task { @MainActor in
            await remote.perform(.put, path: path, parameters: parameters, type: AnyResponse.self)
                .map { _ in }
                .execute(onSuccess: success, onFailure: failure)
        }
    }

    // MARK: - Install / Uninstall
    public func install(pluginSlug: String, success: @escaping (PluginState) -> Void, failure: @escaping (Error) -> Void) {
        let parameters = ["slug": pluginSlug]
        Task { @MainActor in
            await remote.post(path: path(), parameters: parameters, type: PluginStateResponse.self)
                .mapError { error -> Error in
                    if case let .unparsableResponse(_, _, underlyingError) = error, underlyingError is DecodingError {
                        return PluginServiceRemote.ResponseError.decodingFailure
                    }
                    return error
                }
                .flatMap {
                    guard let state = self.pluginState(with: $0) else {
                        return .failure(PluginServiceRemote.ResponseError.decodingFailure)
                    }
                    return .success(state)
                }
                .execute(onSuccess: success, onFailure: failure)
        }
    }

    public func remove(pluginID: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let path = self.path(with: pluginID)
        Task { @MainActor in
            await remote.perform(.delete, path: path, type: AnyResponse.self)
                .map { _ in }
                .execute(onSuccess: success, onFailure: failure)
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

    private func pluginState(with response: PluginStateResponse) -> PluginState? {
        guard
            // The slugs returned are in the form of XXX/YYY
            // The PluginStore uses slugs that are just XXX
            // Extract that information out
            let slug = response.plugin.components(separatedBy: "/").first
        else {
            return nil
        }

        let isActive = response.status == "active"

        return PluginState(id: response.plugin,
                           slug: slug,
                           active: isActive,
                           name: response.name,
                           author: response.author,
                           version: response.version,
                           updateState: .updated, // API Doesn't support this yet
                           autoupdate: false, // API Doesn't support this yet
                           automanaged: false, // API Doesn't support this yet
                           // TODO: Return nil instead of an empty URL when 'plugin_uri' is nil?
                           url: URL(string: response.pluginURI ?? ""),
                           settingsURL: nil)
    }

    // MARK: - Unsupported
    public func updatePlugin(pluginID: String, success: @escaping (PluginState) -> Void, failure: @escaping (Error) -> Void) {
        // NOOP - Not supported by the WP.org REST API
    }

    public func enableAutoupdates(pluginID: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        // NOOP - Not supported by the WP.org REST API

        success()
    }

    public func disableAutoupdates(pluginID: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        // NOOP - Not supported by the WP.org REST API

        success()
    }

    public func activateAndEnableAutoupdates(pluginID: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        // Just activate since API does not support autoupdates yet
        activatePlugin(pluginID: pluginID, success: success, failure: failure)
    }
}

private struct PluginStateResponse: Decodable {
    enum CodingKeys: String, CodingKey {
        case plugin = "plugin"
        case status = "status"
        case name = "name"
        case author = "author"
        case version = "version"
        case pluginURI = "plugin_uri"
    }
    var plugin: String
    var status: String
    var name: String
    var author: String
    var version: String
    var pluginURI: String?
}

private struct AnyResponse: Decodable {
    init(from decoder: Decoder) throws {
        // Do nothing
    }
}
