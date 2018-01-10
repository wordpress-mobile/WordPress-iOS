import Foundation

public struct PluginDirectoryEntry: Equatable {
    public let name: String
    public let slug: String
    public let version: String
    public let lastUpdated: Date

    public let icon: URL?
    public let banner: URL?

    public let author: String?
    public let authorURL: URL?

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
        case banners
        case author
    }

    private enum BannersKeys: String, CodingKey {
        case high
        case low
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        slug = try container.decode(String.self, forKey: .slug)
        version = try container.decode(String.self, forKey: .version)
        lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)

        let icons = try? container.decodeIfPresent([String: String].self, forKey: .icons)
        icon = icons??["2x"].flatMap(URL.init(string:))

        // If there's no hi-res version of the banner, the API returns `high: false`, instead of something more logical,
        // like an empty string or `null`, hence the dance below.
        let banners = try? container.nestedContainer(keyedBy: BannersKeys.self, forKey: .banners)

        if let highRes = try? banners?.decodeIfPresent(String.self, forKey: .high) {
            banner = highRes.flatMap(URL.init(string:))
        } else if let lowRes = try? banners?.decodeIfPresent(String.self, forKey: .low) {
            banner = lowRes.flatMap(URL.init(string:))
        } else {
            banner = nil
        }

        let extractedAuthor = extractAuthor(try? container.decode(String.self, forKey: .author))

        author = extractedAuthor?.name
        authorURL = extractedAuthor?.link
    }
}

// Since the WPOrg API returns `author` as a HTML string (or freeform text), we need to get ugly and parse out the important bits out of it ourselves.
typealias Author = (name: String, link: URL?)
func extractAuthor(_ string: String?) -> Author? {
    guard let data = string?.data(using: .utf8),
        let attributedString = try? NSAttributedString(data: data, options: [.documentType : NSAttributedString.DocumentType.html], documentAttributes: nil) else {
            return nil
    }

    let authorName = attributedString.string
    let authorURL = attributedString.attributes(at: 0, effectiveRange: nil)[.link] as? URL
    return (authorName, authorURL)
}
