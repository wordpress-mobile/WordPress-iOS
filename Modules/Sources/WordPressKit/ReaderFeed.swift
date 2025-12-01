import Foundation

/// ReaderFeed
/// Encapsulates details of a single feed returned by the Reader feed search API
/// (read/feed?q=query)
///
/// The API returns different structures depending on the site type:
/// - WordPress.com sites: Data at root level (URL, title, blog_ID)
/// - Jetpack sites: Data in meta.data.feed
/// - External RSS feeds: Data in meta.data.feed, blog_ID is "0"
///
public struct ReaderFeed: Decodable {
    public var feedID: String? {
        let id = feed?.feedID ?? site?.feedID.map(String.init)
        return id?.nonEmptyID
    }

    public var blogID: String? {
        let id = feed?.blogID ?? site?.id.map(String.init)
        return id?.nonEmptyID
    }

    /// Site/Feed URL with fallback: data.site → data.feed
    /// Prioritizes site URL over feed URL for canonical representation
    public var url: URL? {
        site?.url ?? feed?.url
    }

    /// Site/Feed title with fallback: data.site → data.feed
    /// Prioritizes site name over feed name
    public var title: String? {
        site?.name ?? feed?.name
    }

    /// Feed description with fallback: data.site → data.feed
    public var description: String? {
        site?.description ?? feed?.description
    }

    /// Site icon/avatar URL, prioritizing data.site.icon.img over data.feed.image
    public var iconURL: URL? {
        site?.iconURL ?? feed?.imageURL
    }

    // MARK: - Decodable

    /// Feed data from meta.data.feed
    private var feed: FeedData?

    /// Site data from meta.data.site
    private var site: SiteData?

    public init(from decoder: Decoder) throws {
        let parsed = try ReaderFeedJSON(from: decoder)
        self.feed = parsed.meta?.data?.feed
        self.site = parsed.meta?.data?.site

        // If feed data not found, try parsing inline data from root (WordPress.com format)
        if self.feed == nil, let inlineData = try? InlineData(from: decoder) {
            self.feed = FeedData(from: inlineData)
        }
    }
}

private struct ReaderFeedJSON: Decodable {
    struct Meta: Decodable {
        struct Data: Decodable {
            var feed: FeedData?
            var site: SiteData?
        }

        var data: Data?
    }

    var meta: Meta?
}

/// Represents feed-specific data from meta.data.feed
private struct FeedData: Decodable {
    let feedID: String?
    let blogID: String?
    let name: String?
    let url: URL?
    let description: String?
    let imageURL: URL?

    private enum CodingKeys: String, CodingKey {
        case feedID = "feed_ID"
        case blogID = "blog_ID"
        case name = "name"
        case url = "URL"
        case description = "description"
        case imageURL = "image"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        feedID = try? container.decodeIfPresent(String.self, forKey: .feedID)
        blogID = try? container.decodeIfPresent(String.self, forKey: .blogID)
        name = try? container.decodeIfPresent(String.self, forKey: .name)
        url = try? container.decodeIfPresent(URL.self, forKey: .url)
        description = try? container.decodeIfPresent(String.self, forKey: .description)
        imageURL = try? container.decodeIfPresent(URL.self, forKey: .imageURL)
    }

    init(from inlineData: InlineData) {
        self.feedID = inlineData.feedID
        self.blogID = inlineData.blogID
        self.name = inlineData.title
        self.url = inlineData.url
        self.description = nil
        self.imageURL = nil
    }
}

/// Represents site-specific data from meta.data.site
private struct SiteData: Decodable {
    let feedID: Int?
    let id: Int?
    let name: String?
    let url: URL?
    let description: String?
    let iconURL: URL?

    private enum CodingKeys: String, CodingKey {
        case feedID = "feed_ID"
        case id = "ID"
        case name = "name"
        case url = "URL"
        case description = "description"
        case icon = "icon"
    }

    private enum IconKeys: CodingKey {
        case img
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        feedID = try? container.decodeIfPresent(Int.self, forKey: .feedID)
        id = try? container.decodeIfPresent(Int.self, forKey: .id)
        name = try? container.decodeIfPresent(String.self, forKey: .name)
        url = try? container.decodeIfPresent(URL.self, forKey: .url)
        description = try? container.decodeIfPresent(String.self, forKey: .description)

        // Decode icon.img if icon dictionary exists
        if let iconContainer = try? container.nestedContainer(keyedBy: IconKeys.self, forKey: .icon) {
            iconURL = try? iconContainer.decode(URL.self, forKey: .img)
        } else {
            iconURL = nil
        }
    }
}

/// Represents inline feed data (WordPress.com sites)
/// Used when feed data appears at root level instead of nested in meta.data.feed.
/// In practice, it should never be necessary. It's a fallback.
private struct InlineData: Decodable {
    let feedID: String?
    let blogID: String?
    let title: String?
    let url: URL?

    private enum CodingKeys: String, CodingKey {
        case feedID = "feed_ID"
        case blogID = "blog_ID"
        case title = "title"
        case url = "URL"
    }
}

private extension String {
    var nonEmptyID: String? {
        guard !isEmpty && self != "0" else {
            return nil
        }
        return self
    }
}
