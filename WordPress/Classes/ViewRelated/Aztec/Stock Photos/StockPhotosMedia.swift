import Foundation
import WPMediaPicker

/*** JSON Structure of a StockPhoto object coming from the API ***
{
    "ID": "PEXELS-710916",
    "URL": "https://images.pexels.com/photos/710916/pexels-photo-710916.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940",
    "title": "pexels-photo-710916.jpeg",
    "date": "2018-03-28 00:00:00",
    "name": "pexels-photo-710916.jpeg",
    "file": "pexels-photo-710916.jpeg",
    "guid": "{\"url\":\"https:\\/\\/images.pexels.com\\/photos\\/710916\\/pexels-photo-710916.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940\",\"name\":\"pexels-photo-710916.jpeg\",\"title\":\"pexels-photo-710916.jpeg\"}",
    "height": 1253,
    "width": 1880,
    "thumbnails": {
        "large": "https://images.pexels.com/photos/710916/pexels-photo-710916.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940",
        "medium": "https://images.pexels.com/photos/710916/pexels-photo-710916.jpeg?auto=compress&cs=tinysrgb&h=350",
        "post-thumbnail": "https://images.pexels.com/photos/710916/pexels-photo-710916.jpeg?auto=compress&cs=tinysrgb&h=130",
        "thumbnail": "https://images.pexels.com/photos/710916/pexels-photo-710916.jpeg?auto=compress&cs=tinysrgb&fit=crop&h=200&w=280"
    },
    "type": "image",
    "extension": "jpeg"
}
*/

struct ThumbnailCollection {
    private(set) var largeURL: URL
    private(set) var mediumURL: URL
    private(set) var postThumbnailURL: URL
    private(set) var thumbnailURL: URL
}

/// Models a Stock Photo
///
final class StockPhotosMedia: NSObject {
    private(set) var id: String
    private(set) var URL: URL
    private(set) var title: String
    private(set) var name: String
    private(set) var size: CGSize
    private(set) var thumbnails: ThumbnailCollection

    init(id: String, URL: URL, title: String, name: String, size: CGSize, thumbnails: ThumbnailCollection) {
        self.id = id
        self.URL = URL
        self.title = title
        self.name = name
        self.size = size
        self.thumbnails = thumbnails
    }
}

extension StockPhotosMedia: WPMediaAsset {
    func image(with size: CGSize, completionHandler: @escaping WPMediaImageBlock) -> WPMediaRequestID {

        //Temporary loading image from URL
        DispatchQueue.global().async {
            do {
                let data = try Data(contentsOf: self.thumbnails.postThumbnailURL)
                let image = UIImage(data: data)
                completionHandler(image, nil)
            } catch {
                completionHandler(nil, error)
            }
        }

        let number = Int32(id) ?? 0
        return number as WPMediaRequestID
    }

    func cancelImageRequest(_ requestID: WPMediaRequestID) {
        //
    }

    func videoAsset(completionHandler: @escaping WPMediaAssetBlock) -> WPMediaRequestID {
        return 0
    }

    func assetType() -> WPMediaType {
        return .image
    }

    func duration() -> TimeInterval {
        return 0
    }

    func baseAsset() -> Any {
        return self
    }

    func identifier() -> String {
        return id
    }

    func date() -> Date {
        return Date()
    }

    func pixelSize() -> CGSize {
        return size
    }
}

extension ThumbnailCollection: Decodable {
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
        postThumbnailURL = try values.decode(String.self, forKey: .large).asURL()
        thumbnailURL = try values.decode(String.self, forKey: .large).asURL()
    }
}

extension StockPhotosMedia: Decodable {
    enum CodingKeys: String, CodingKey {
        case ID
        case URL
        case title
        case name
        case thumbnails
    }

    convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let id = try values.decode(String.self, forKey: .ID)
        let URL = try values.decode(String.self, forKey: .URL).asURL()
        let title = try values.decode(String.self, forKey: .title)
        let name = try values.decode(String.self, forKey: .name)
        let size: CGSize = .zero
        let thumbnails = try values.decode(ThumbnailCollection.self, forKey: .thumbnails)

        self.init(id: id, URL: URL, title: title, name: name, size: size, thumbnails: thumbnails)
    }
}
