import Foundation

public struct PluginDirectoryResponse: Decodable, Equatable {
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

        plugins = try container.decode([PluginDirectoryEntry].self, forKey: .plugins)
        let info = try container.nestedContainer(keyedBy: InfoKeys.self, forKey: .info)

        let pageNumber = try info.decode(Int.self, forKey: .page)

        pageMetadata = PluginDirectoryPageMetadata(page: pageNumber, pluginSlugs: plugins.map { $0.slug} )
    }

    public static func ==(lhs: PluginDirectoryResponse, rhs: PluginDirectoryResponse) -> Bool {
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
