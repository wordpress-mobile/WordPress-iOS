import Foundation

public struct SitePlugins: Codable {
    public var plugins: [PluginState]
    public var capabilities: SitePluginCapabilities
}
