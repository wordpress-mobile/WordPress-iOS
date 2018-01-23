import Foundation

public struct PluginDirectoryFeedPage: Decodable, Equatable {
    public let pageMetadata: PluginDirectoryPageMetadata
    public let plugins: [PluginDirectoryEntry]

    private enum CodingKeys: String, CodingKey {
        case info
        case plugins
    }

    private enum InfoKeys: String, CodingKey {
        case page
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // The API we're using has a bug where sometimes the `plugins` field is an Array, and sometimes
        // it's a dictionary with numerical keys. Until the responsible parties can deploy a patch,
        // here's a workaround.
        pluginParsing: do {
            if let parsedPlugins = try? container.decode([PluginDirectoryEntry].self, forKey: .plugins) {
                self.plugins = parsedPlugins
                break pluginParsing
            }

            let parsedPlugins = try container.decode([Int: PluginDirectoryEntry].self, forKey: .plugins)

            self.plugins = parsedPlugins
                .sorted { $0.key < $1.key }
                .flatMap { $0.value }
        }

        let info = try container.nestedContainer(keyedBy: InfoKeys.self, forKey: .info)

        let pageNumber = try info.decode(Int.self, forKey: .page)

        pageMetadata = PluginDirectoryPageMetadata(page: pageNumber, pluginSlugs: plugins.map { $0.slug} )
    }

    public static func ==(lhs: PluginDirectoryFeedPage, rhs: PluginDirectoryFeedPage) -> Bool {
        return lhs.pageMetadata == rhs.pageMetadata
            && lhs.plugins == rhs.plugins
    }

}


public struct PluginDirectoryPageMetadata: Equatable {
    public let page: Int
    public let pluginSlugs: [String]

    public static func ==(lhs: PluginDirectoryPageMetadata, rhs: PluginDirectoryPageMetadata) -> Bool {
        return lhs.page == rhs.page
            && lhs.pluginSlugs == rhs.pluginSlugs
    }
}


