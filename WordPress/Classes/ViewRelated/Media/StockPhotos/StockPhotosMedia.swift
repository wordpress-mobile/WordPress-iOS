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
        largeURL = try values.decode(String.self, forKey: .large).asURL()
        mediumURL = try values.decode(String.self, forKey: .medium).asURL()
        postThumbnailURL = try values.decode(String.self, forKey: .postThumbnail).asURL()
        thumbnailURL = try values.decode(String.self, forKey: .thumbnail).asURL()
    }
}

extension StockPhotosMedia: Decodable {
    enum CodingKeys: String, CodingKey {
        case ID
        case URL
        case title
        case name
        case thumbnails
        case caption
    }

    convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let id = try values.decode(String.self, forKey: .ID)
        let URL = try values.decode(String.self, forKey: .URL).asURL()
        let title = try values.decode(String.self, forKey: .title)
        let name = try values.decode(String.self, forKey: .name)
        let caption = try values.decode(String.self, forKey: .caption)
        let size: CGSize = .zero
        let thumbnails = try values.decode(ThumbnailCollection.self, forKey: .thumbnails)

        self.init(id: id, URL: URL, title: title, name: name, caption: caption, size: size, thumbnails: thumbnails)
    }
}
