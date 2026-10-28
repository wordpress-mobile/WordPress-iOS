import Foundation

struct RemoteReaderSimplePostEnvelope: Decodable {
    let posts: [RemoteReaderSimplePost]
}

public struct RemoteReaderSimplePost: Decodable {
    public enum PostType: Int {
        case local
        case global
        case unknown
    }

    public let postID: Int
    public let postUrl: String
    public let siteID: Int
    public let isFollowing: Bool
    public let title: String
    public let author: RemoteReaderSimplePostAuthor
    public let excerpt: String
    public let siteName: String
    public let featuredImageUrl: String?
    public let featuredMedia: RemoteReaderSimplePostFeaturedMedia?
    public let railcar: RemoteReaderSimplePostRailcar

    /// The image to show for the post, or nil when the API supplied none that loads as an image.
    ///
    /// `featured_media` describes the first media in the post, which can be a video. Its `uri` is
    /// then an embed page (a YouTube player URL, for example), not an image, so only `image` media
    /// is used.
    public var featuredImageURL: URL? {
        if let featuredImageUrl, !featuredImageUrl.isEmpty {
            return URL(string: featuredImageUrl)
        }
        if let featuredMedia, featuredMedia.type == "image", let uri = featuredMedia.uri, !uri.isEmpty {
            return URL(string: uri)
        }
        return nil
    }

    public var postType: PostType {
        switch railcar.fetchAlgo {
        case let algoStr where algoStr.contains("local"):
            return .local
        case let algoStr where algoStr.contains("global"):
            return .global
        default:
            return .unknown
        }
    }

    private enum CodingKeys: String, CodingKey {
        case postID = "ID"
        case postUrl = "URL"
        case siteID = "site_ID"
        case isFollowing = "is_following"
        case title
        case author
        case excerpt
        case siteName = "site_name"
        case featuredImageUrl = "featured_image"
        case featuredMedia = "featured_media"
        case railcar
    }
}

public struct RemoteReaderSimplePostAuthor: Decodable {
    public let name: String
}

public struct RemoteReaderSimplePostFeaturedMedia: Decodable {
    public let uri: String?
    public let type: String?
}

public struct RemoteReaderSimplePostRailcar: Decodable {
    public let fetchAlgo: String

    private enum CodingKeys: String, CodingKey {
        case fetchAlgo = "fetch_algo"
    }
}
