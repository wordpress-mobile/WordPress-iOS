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

        let authorHTML = try? container.decode(String.self, forKey: .author)

        author = extractName(authorHTML)
        authorURL = extractURL(authorHTML)
    }
}

// Since the WPOrg API returns `author` as a HTML string (or freeform text), we need to get ugly and parse out the important bits out of it ourselves.
private func extractName(_ authorHTML: String?) -> String? {
    guard let author = authorHTML,
          let closingTagIndex = author.index(of: ">") else {
            // Some plugins don't have HTML `<a>` in them, just the name.
            // Just return the original string in that case.
            return authorHTML
    }

    let slice = String(author[author.index(after: closingTagIndex)...])
    return slice.removingSuffix("</a>")
}

private func extractURL(_ authorHTML: String?) -> URL? {
    guard let author = authorHTML else {
        return nil
    }

    let withoutPrefix = author.removingPrefix("<a href=\"")

    guard let closingTagIndex = withoutPrefix.index(of: ">") else { return nil }
    let slice = withoutPrefix[...withoutPrefix.index(closingTagIndex, offsetBy: -2)]
    // Offset by two characters: One is the closing angled bracket itself and the other is closing quotation mark.

    return URL(string: String(slice))
}
