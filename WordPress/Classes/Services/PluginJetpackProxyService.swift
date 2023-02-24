/// Plugin management service through the Jetpack Proxy.
///
class PluginJetpackProxyService {

    // MARK: Properties

    private let remote: JetpackProxyServiceRemote

    init(remote: JetpackProxyServiceRemote? = nil) {
        self.remote = remote ?? .init(wordPressComRestApi: .defaultApi(in: ContextManager.shared.mainContext))
    }

    // MARK: Methods

    /// Installs a plugin for a site with the given `siteID` via the Jetpack Proxy API.
    ///
    /// - Note: The `pluginSlug` value is currently only obtainable from the WordPress.org REST v1.1 or v1.2 API.
    /// The documentation for this API is rather sparse, so we'll have to test things ourselves.
    /// See [this page](https://codex.wordpress.org/WordPress.org_API#Plugins) for more details.
    ///
    /// - Parameters:
    ///   - siteID: The dotcom ID of the Jetpack-connected site.
    ///   - pluginSlug: A string used as an identifier for the plugin. See the note above.
    ///   - active: Whether the plugin should be activated immediately after installation.
    ///   - completion: Closure called after the request completes.
    /// - Returns: A Progress object that can be used to cancel the request. Discardable.
    @discardableResult
    func installPlugin(for siteID: Int,
                       pluginSlug: String,
                       active: Bool = false,
                       completion: @escaping (Result<Void, Error>) -> Void) -> Progress? {
        let parameters = [
            "slug": pluginSlug,
            "status": active ? "active" : "inactive"
        ]

        return remote.proxyRequest(for: siteID,
                                   path: Constants.pluginsPath,
                                   method: .post,
                                   parameters: parameters) { result in
            switch result {
            case .success:
                // we're ignoring the response object for now.
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Private helpers

private extension PluginJetpackProxyService {

    enum Constants {
        static let pluginsPath = "/wp/v2/plugins"
    }

}
