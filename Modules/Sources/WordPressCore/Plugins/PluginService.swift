import Foundation
import UIKit
import WordPressAPI
@preconcurrency import WordPressAPIInternal

public actor PluginService: PluginServiceProtocol {
    private let client: WordPressClient
    private let wpOrgClient: WordPressOrgApiClient
    private let installedPluginDataStore = InMemoryInstalledPluginDataStore()
    private let pluginDirectoryDataStore = InMemoryPluginDirectoryDataStore()
    private let pluginDirectoryBrowserDataStore = CategorizedPluginInformationDataStore()
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

    public func fetchPluginInformation(slug: PluginWpOrgDirectorySlug) async throws {
        // Considering fetched plugin info are stored in memory at the moment, it's okay to not re-fetch plugin info
        // if it's already fetched.
        if try await pluginDirectoryDataStore.get(slug) != nil {
            return
        }

        let plugin = try await wpOrgClient.pluginInformation(slug: slug)
        try await pluginDirectoryDataStore.store([plugin])
    }

    public func findInstalledPlugin(slug: PluginWpOrgDirectorySlug) async throws -> InstalledPlugin? {
        try await installedPluginDataStore.list(query: .slug(slug)).first
    }

    public func installedPluginsUpdates(query: PluginDataStoreQuery) async -> AsyncStream<Result<[InstalledPlugin], Error>> {
        await installedPluginDataStore.listStream(query: query)
    }

    public func pluginInformationUpdates(query: PluginDirectoryDataStoreQuery) async -> AsyncStream<Result<[PluginInformation], Error>> {
        await pluginDirectoryDataStore.listStream(query: query)
    }

    public func resolveIconURL(of slug: PluginWpOrgDirectorySlug, plugin: PluginInformation?) async -> URL? {
        // TODO: Cache the icon URL

        if let plugin, let url = await findIconFromPluginDirectory(pluginInfo: plugin) {
            return url
        }

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

    public func fetchPluginsDirectory(category: WordPressOrgApiPluginDirectoryCategory) async throws {
        // Hard-code the pagination parameters for now. We can suface these parameters when the app needs pagination.
        let plugins = try await wpOrgClient.browsePlugins(category: category, page: 1, pageSize: 10).plugins
        try await pluginDirectoryBrowserDataStore.delete(query: .category(category))
        try await pluginDirectoryBrowserDataStore.store([CategorizedPluginInformation(category: category, plugins: plugins)])
    }

    public func pluginDirectoryUpdates(query: CategorizedPluginInformationDataStoreQuery) async -> AsyncStream<Result<[CategorizedPluginInformation], Error>> {
        await pluginDirectoryBrowserDataStore.listStream(query: query)
    }

    public func searchPluginsDirectory(input: String) async throws -> [PluginInformation] {
        // Hard-code the pagination parameters for now. We can suface these parameters when the app needs pagination.
        try await wpOrgClient.searchPlugins(search: input, page: 1, pageSize: 20).plugins
    }
}

private extension PluginService {
    func findIconFromPluginDirectory(slug: PluginWpOrgDirectorySlug) async -> URL? {
        let pluginInfo: PluginInformation

        do {
            if try await pluginDirectoryDataStore.get(slug) == nil {
                try await fetchPluginInformation(slug: slug)
            }

            if let info = try await pluginDirectoryDataStore.get(slug) {
                pluginInfo = info
            } else {
                return nil
            }
        } catch {
            return nil
        }

        return await findIconFromPluginDirectory(pluginInfo: pluginInfo)
    }

    func findIconFromPluginDirectory(pluginInfo: PluginInformation) async -> URL? {
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
