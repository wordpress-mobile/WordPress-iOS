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
        case feed
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

        // Try to parse both site and feed data from meta.data
        do {
            let metaContainer = try rootContainer.nestedContainer(keyedBy: MetaKeys.self, forKey: .meta)
            let dataContainer = try metaContainer.nestedContainer(keyedBy: DataKeys.self, forKey: .data)

            let siteData = try? dataContainer.decode(SiteOrFeedData.self, forKey: .site)
            let feedData = try? dataContainer.decode(SiteOrFeedData.self, forKey: .feed)

            // Use data from either source, preferring site data when both are available
            feedDescription = siteData?.description ?? feedData?.description
            blavatarURL = siteData?.iconURL ?? feedData?.iconURL

            // Fixes CMM-1002: in some cases, the backend fails to embed certain fields
            // directly in the feed object
            if feedURL == nil {
                feedURL = siteData?.url ?? feedData?.url
            }
            if title == nil {
                title = siteData?.title ?? feedData?.title
            }
        } catch {
        }

        self.url = feedURL
        self.title = title
        self.feedDescription = feedDescription
        self.blavatarURL = blavatarURL
    }
}

private struct SiteOrFeedData: Decodable {
    var title: String?
    var description: String?
    var iconURL: URL?
    var url: URL?

    enum CodingKeys: String, CodingKey {
        case description
        case icon
        case url = "URL"
        case name
    }

    private enum IconKeys: CodingKey {
        case img
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        title = try? container.decodeIfPresent(String.self, forKey: .name)
        description = try? container.decodeIfPresent(String.self, forKey: .description)
        url = try? container.decodeIfPresent(URL.self, forKey: .url)

        // Try to decode the icon URL from the nested icon dictionary
        if let iconContainer = try? container.nestedContainer(keyedBy: IconKeys.self, forKey: .icon) {
            iconURL = try? iconContainer.decode(URL.self, forKey: .img)
        }
    }
}

extension ReaderFeed: CustomStringConvertible {
    public var description: String {
        return "<Feed | URL: \(String(describing: url)), title: \(String(describing: title)), feedID: \(String(describing: feedID)), blogID: \(String(describing: blogID))>"
    }
}
