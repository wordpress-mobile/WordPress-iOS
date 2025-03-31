import Foundation

/// Models a Stock Photo
///
final class StockPhotosMedia: NSObject {
    private(set) var id: String
    private(set) var URL: URL
    private(set) var title: String
    private(set) var name: String
    private(set) var caption: String
    private(set) var size: CGSize
    private(set) var thumbnails: ThumbnailCollection

    struct ThumbnailCollection {
        private(set) var largeURL: URL
        private(set) var mediumURL: URL
        private(set) var postThumbnailURL: URL
        private(set) var thumbnailURL: URL
    }

    init(id: String, URL: URL, title: String, name: String, caption: String, size: CGSize, thumbnails: ThumbnailCollection) {
        self.id = id
        self.URL = URL
        self.title = title
        self.name = name
        self.caption = caption
        self.size = size
        self.thumbnails = thumbnails
    }
}

extension StockPhotosMedia: ExternalMediaAsset {
    var assetMediaType: MediaType { .image }
    var thumbnailURL: URL { thumbnails.thumbnailURL }
    var largeURL: URL { thumbnails.largeURL }
}

// MARK: - Decodable conformance

extension StockPhotosMedia.ThumbnailCollection: Decodable {
    enum CodingKeys: String, CodingKey {
        case large
        case medium
        case postThumbnail = "post-thumbnail"
        case thumbnail
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        largeURL = try values.decode(URL.self, forKey: .large)
        mediumURL = try values.decode(URL.self, forKey: .medium)
        postThumbnailURL = try values.decode(URL.self, forKey: .postThumbnail)
        thumbnailURL = try values.decode(URL.self, forKey: .thumbnail)
    }
}

extension StockPhotosMedia: Decodable {
    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case url = "URL"
        case title
        case name
        case thumbnails
        case caption
    }

    convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let id = try values.decode(String.self, forKey: .id)
        // Notice the Foundation namespace. It's required to disambiguate from the URL property.
        // Will get to rename that eventually, but it's out of scope at the time of this change.
        let url = try values.decode(Foundation.URL.self, forKey: .url)
        let title = try values.decode(String.self, forKey: .title)
        let name = try values.decode(String.self, forKey: .name)
        let caption = try values.decode(String.self, forKey: .caption)
        let size: CGSize = .zero
        let thumbnails = try values.decode(ThumbnailCollection.self, forKey: .thumbnails)

        self.init(id: id, URL: url, title: title, name: name, caption: caption, size: size, thumbnails: thumbnails)
    }
}
