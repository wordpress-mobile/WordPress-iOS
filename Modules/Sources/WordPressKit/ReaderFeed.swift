import Foundation

/// ReaderFeed
/// Encapsulates details of a single feed returned by the Reader feed search API
/// (read/feed?q=query)
///
public struct ReaderFeed: Decodable {
    public let url: URL?
    public let title: String?
    public let feedDescription: String?
    public let feedID: String?
    public let blogID: String?
    public let blavatarURL: URL?

    private enum CodingKeys: String, CodingKey {
        case url = "URL"
        case title = "title"
        case feedID = "feed_ID"
        case blogID = "blog_ID"
        case meta = "meta"
    }

    private enum MetaKeys: CodingKey {
        case data
    }

    private enum DataKeys: CodingKey {
        case site
    }

    private enum SiteKeys: String, CodingKey {
        case description
        case icon
        case url = "URL"
        case name
    }

    private enum IconKeys: CodingKey {
        case img
    }

    public init(from decoder: Decoder) throws {
        // We have to manually decode the feed from the JSON, for a couple of reasons:
        // - Some feeds have no `icon` dictionary
        // - Some feeds have no `data` dictionary
        // - We want to decode whatever we can get, and not fail if neither of those exist
        let rootContainer = try decoder.container(keyedBy: CodingKeys.self)

        var feedURL = try? rootContainer.decodeIfPresent(URL.self, forKey: .url)
        var title = try? rootContainer.decodeIfPresent(String.self, forKey: .title)
        feedID = try? rootContainer.decode(String.self, forKey: .feedID)
        blogID = try? rootContainer.decode(String.self, forKey: .blogID)

        var feedDescription: String?
        var blavatarURL: URL?

        do {
            let metaContainer = try rootContainer.nestedContainer(keyedBy: MetaKeys.self, forKey: .meta)
            let dataContainer = try metaContainer.nestedContainer(keyedBy: DataKeys.self, forKey: .data)
            let siteContainer = try dataContainer.nestedContainer(keyedBy: SiteKeys.self, forKey: .site)
            feedDescription = try? siteContainer.decode(String.self, forKey: .description)

            let iconContainer = try siteContainer.nestedContainer(keyedBy: IconKeys.self, forKey: .icon)
            blavatarURL = try? iconContainer.decode(URL.self, forKey: .img)

            // Fixes CMM-1002: in some cases, the backend fails to embed certain fields
            // directly in the feed object
            if feedURL == nil {
                feedURL = try? siteContainer.decodeIfPresent(URL.self, forKey: .url)
            }
            if title == nil {
                title = try? siteContainer.decodeIfPresent(String.self, forKey: .name)
            }
        } catch {
        }

        self.url = feedURL
        self.title = title
        self.feedDescription = feedDescription
        self.blavatarURL = blavatarURL
    }
}

extension ReaderFeed: CustomStringConvertible {
    public var description: String {
        return "<Feed | URL: \(String(describing: url)), title: \(String(describing: title)), feedID: \(String(describing: feedID)), blogID: \(String(describing: blogID))>"
    }
}
