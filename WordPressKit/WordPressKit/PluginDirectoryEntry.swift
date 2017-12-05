import Foundation

public struct PluginDirectoryEntry {
    public let name: String
    public let slug: String
    public let version: String
    public let icon: URL?
}

extension PluginDirectoryEntry: Decodable {
    private enum CodingKeys : CodingKey {
        case name
        case slug
        case version
        case icons
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        slug = try container.decode(String.self, forKey: .slug)
        version = try container.decode(String.self, forKey: .version)
        let icons = try? container.decodeIfPresent([String: String].self, forKey: .icons)
        icon = icons??["2x"].flatMap(URL.init(string:))
    }
}
