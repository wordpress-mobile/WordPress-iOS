import Foundation
import WordPressAPI
import WordPressAPIInternal

public protocol PluginServiceProtocol: Actor {

    func fetchInstalledPlugins() async throws
    func fetchPluginInformation(slug: PluginWpOrgDirectorySlug) async throws

    func installedPluginsUpdates(query: PluginDataStoreQuery) async -> AsyncStream<Result<[InstalledPlugin], Error>>
    func pluginInformationUpdates(query: PluginDirectoryDataStoreQuery) async -> AsyncStream<Result<[PluginInformation], Error>>
    func newVersionUpdates(query: PluginUpdateChecksDataStoreQuery) async -> AsyncStream<Result<[UpdateCheckPluginInfo], Error>>

    func findInstalledPlugin(slug: PluginWpOrgDirectorySlug) async throws -> InstalledPlugin?
    func installedPlugins(query: PluginDataStoreQuery) async throws -> [InstalledPlugin]

    func resolveIconURL(of slug: PluginWpOrgDirectorySlug, plugin: PluginInformation?) async -> URL?

    func updatePluginStatus(plugin: InstalledPlugin, activated: Bool) async throws -> InstalledPlugin

    func uninstalledPlugin(slug: PluginSlug) async throws
    func installPlugin(slug: PluginWpOrgDirectorySlug) async throws -> InstalledPlugin

    func fetchPluginsDirectory(category: WordPressOrgApiPluginDirectoryCategory) async throws
    func pluginDirectoryUpdates(query: CategorizedPluginInformationDataStoreQuery) async -> AsyncStream<Result<[CategorizedPluginInformation], Error>>

    func searchPluginsDirectory(input: String) async throws -> [PluginInformation]

}

extension PluginServiceProtocol {
    public func resolveIconURL(of plugin: InstalledPlugin) async -> URL? {
        guard let slug = plugin.possibleWpOrgDirectorySlug else { return nil }
        return await resolveIconURL(of: slug, plugin: nil)
    }
}
