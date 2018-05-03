import Foundation

extension PluginStoreState: Codable {

    private enum CodingKeys: String, CodingKey {
        case plugins
        case featuredPluginSlugs
        case directoryFeeds
        case directoryEntries
    }


    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        plugins = try container.decode([JetpackSiteRef: SitePlugins].self, forKey: .plugins)
        featuredPluginsSlugs = try container.decode([String].self, forKey: .featuredPluginSlugs)
        directoryFeeds = try container.decode([String: PluginDirectoryPageMetadata].self, forKey: .directoryFeeds)
        directoryEntries = try container.decode([String: PluginDirectoryEntryState].self, forKey: .directoryEntries)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(plugins, forKey: .plugins)
        try container.encode(featuredPluginsSlugs, forKey: .featuredPluginSlugs)
        try container.encode(directoryFeeds, forKey: .directoryFeeds)
        try container.encode(directoryEntries, forKey: .directoryEntries)
    }

}
