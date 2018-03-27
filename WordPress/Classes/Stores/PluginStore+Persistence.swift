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

extension PluginStore {

    private static let cacheFilename = "plugins.json"

    func writeCachedJSON() {
        do {
            let jsonEncoder = JSONEncoder.init()
            let encodedStore = try jsonEncoder.encode(state)

            let documentsPath = try FileManager.default.url(for: .documentDirectory,
                                                            in: .userDomainMask,
                                                            appropriateFor: nil,
                                                            create: true)
            let targetURL = documentsPath.appendingPathComponent(PluginStore.cacheFilename)

            try encodedStore.write(to: targetURL, options: [.atomic])
        } catch {
            DDLogError("[PluginStore Error] \(error)")
        }
    }

    static func initialState() -> PluginStoreState? {
        do {
            let fileURL = try FileManager.default.url(for: .documentDirectory,
                                                   in: .userDomainMask,
                                                   appropriateFor: nil,
                                                   create: true).appendingPathComponent(PluginStore.cacheFilename)

            let data = try Data(contentsOf: fileURL)
            let state = try JSONDecoder().decode(PluginStoreState.self, from: data)

            return state
        } catch {
            DDLogError("[PluginStore Error] \(error)")
            return nil
        }
    }
}
