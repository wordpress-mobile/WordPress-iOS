import Foundation
import WordPressAPI

public protocol PluginServiceProtocol: Actor {

    func fetchInstalledPlugins() async throws

    func installedPluginsUpdates() async -> AsyncStream<Result<[InstalledPlugin], Error>>

    func resolveIconURL(of slug: PluginWpOrgDirectorySlug) async -> URL?

}

extension PluginServiceProtocol {
    public func resolveIconURL(of plugin: InstalledPlugin) async -> URL? {
        guard let slug = plugin.possibleWpOrgDirectorySlug else { return nil }
        return await resolveIconURL(of: slug)
    }
}
