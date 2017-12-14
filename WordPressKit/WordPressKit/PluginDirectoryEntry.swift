import Foundation

public struct PluginDirectoryEntry: Equatable {
    public let name: String
    public let slug: String
    public let version: String
    public let lastUpdated: Date
    public let icon: URL?

    public static func ==(lhs: PluginDirectoryEntry, rhs: PluginDirectoryEntry) -> Bool {
        return lhs.name == rhs.name
            && lhs.slug == rhs.slug
            && lhs.version == rhs.version
            && lhs.lastUpdated == rhs.lastUpdated
            && lhs.icon == rhs.icon
    }
}

extension PluginDirectoryEntry: Decodable {
    private enum CodingKeys: String, CodingKey {
        case name
        case slug
        case version
        case lastUpdated = "last_updated"
        case icons
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        slug = try container.decode(String.self, forKey: .slug)
        version = try container.decode(String.self, forKey: .version)
        lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
        let icons = try? container.decodeIfPresent([String: String].self, forKey: .icons)
        icon = icons??["2x"].flatMap(URL.init(string:))
    }
}
