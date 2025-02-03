import Foundation
import UIKit
import WordPressAPI
@preconcurrency import WordPressAPIInternal

public actor PluginService: PluginServiceProtocol {
    private let client: WordPressClient
    private let wpOrgClient: WordPressOrgApiClient
    private let installedPluginDataStore = InMemoryInstalledPluginDataStore()
    private let urlSession: URLSession

    public init(client: WordPressClient) {
        self.client = client
        self.urlSession = URLSession(configuration: .ephemeral)
        wpOrgClient = WordPressOrgApiClient(requestExecutor: urlSession)
    }

    public func fetchInstalledPlugins() async throws {
        let response = try await self.client.api.plugins.listWithViewContext(params: .init())
        let plugins = response.data.map(InstalledPlugin.init(plugin:))
        try await installedPluginDataStore.store(plugins)
    }

    public func installedPluginsUpdates(query: PluginDataStoreQuery) async -> AsyncStream<Result<[InstalledPlugin], Error>> {
        await installedPluginDataStore.listStream(query: query)
    }

    public func resolveIconURL(of slug: PluginWpOrgDirectorySlug) async -> URL? {
        // TODO: Cache the icon URL

        if let url = await findIconFromPluginDirectory(slug: slug) {
            return url
        }

        if let url = await findIconFromSVNServer(slug: slug) {
            return url
        }

        return nil
    }

    public func togglePluginActivation(slug: PluginSlug) async throws {
        let plugin = try await client.api.plugins.retrieveWithViewContext(pluginSlug: slug)
        let newStatus: PluginStatus = plugin.data.status == .inactive ? (plugin.data.networkOnly ? .networkActive : .active) : .inactive
        let newPlugin = try await client.api.plugins.update(pluginSlug: slug, params: .init(status: newStatus))
        try await installedPluginDataStore.store([.init(plugin: newPlugin.data)])
    }

    public func uninstalledPlugin(slug: PluginSlug) async throws {
        let _ = try await client.api.plugins.delete(pluginSlug: slug)
        try await installedPluginDataStore.delete(query: .slug(slug))
    }

}

private extension PluginService {
    func findIconFromPluginDirectory(slug: PluginWpOrgDirectorySlug) async -> URL? {
        guard let pluginInfo = try? await wpOrgClient.pluginInformation(slug: slug) else { return nil }
        guard let icons = pluginInfo.icons else { return nil }

        let supportedFormat: Set<String> = ["png", "jpg", "jpeg", "gif"]
        let urls: [String?] = [icons.default, icons.high, icons.low]
        for string in urls {
            guard let string, let url = URL(string: string) else { continue }

            if supportedFormat.contains(url.pathExtension) {
                return url
            }
        }

        return nil
    }

    func findIconFromSVNServer(slug: PluginWpOrgDirectorySlug) async -> URL? {
        let url = URL(string: "https://ps.w.org")!
            .appending(path: slug.slug)
            .appending(path: "assets")
        let size = [256, 128]
        let supportedFormat = ["png", "jpg", "jpeg", "gif"]
        let candidates = zip(size, supportedFormat).map { size, format in
            url.appending(path: "icon-\(size)x\(size).\(format)")
        }

        for url in candidates {
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"

            if let (_, response) = try? await urlSession.data(for: request),
               (response  as? HTTPURLResponse)?.statusCode == 200 {
                return url
            }
        }

        return nil
    }
}
