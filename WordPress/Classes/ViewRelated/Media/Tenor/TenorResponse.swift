import Foundation
import MobileCoreServices

typealias TenorGifFormat = TenorMedia.MediaCodingKeys

class TenorResponse: NSObject, Decodable {
    let next: String
    let results: [TenorMedia]
}

class TenorMedia: NSObject, Decodable {
    enum CodingKeys: String, CodingKey {
        case id
        case created
        case itemurl
        case title
        case media
    }

    enum MediaCodingKeys: String, CodingKey, CaseIterable {
        case nanogif
        case tinygif
        case mediumgif
        case gif
    }

    let id: String
    let created: Date
    let itemurl: String
    let title: String

    // Data format in the response has unnecessary depth. We'll convert it to a more optimal format
    var gifs: [TenorGifFormat: TenorGif]

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: CodingKeys.id)

        let createdDate = try container.decode(Float.self, forKey: CodingKeys.created)
        created = Date(timeIntervalSince1970: Double(createdDate))

        itemurl = try container.decode(String.self, forKey: CodingKeys.itemurl)
        title = try container.decode(String.self, forKey: CodingKeys.title)

        var mediaContainer = try container.nestedUnkeyedContainer(forKey: CodingKeys.media)

        gifs = [TenorGifFormat: TenorGif]()

        while !mediaContainer.isAtEnd {
            let gifsContainer = try mediaContainer.nestedContainer(keyedBy: MediaCodingKeys.self)
            for key in MediaCodingKeys.allCases {
                gifs[key] = try gifsContainer.decode(TenorGif.self, forKey: key)
            }
        }
    }
}

class TenorGif: NSObject, Codable {
    let url: String
    let dims: [Int]
    let preview: String
}

// MARK - Helpers needed by WPMediaAsset conformance

extension TenorMedia {
    var previewGif: TenorGif {
        return gifs[.tinygif]!
    }

    var largeGif: TenorGif {
        return gifs[.gif]!
    }

    var previewURL: URL {
        return NSURL(string: previewGif.url)! as URL
    }

    var staticThumbnailURL: URL {
        return NSURL(string: previewGif.preview)! as URL
    }
}

// MARK - WPMediaAsset conformance

extension TenorMedia: WPMediaAsset {
    func image(with size: CGSize, completionHandler: @escaping WPMediaImageBlock) -> WPMediaRequestID {
        let url = imageURL(with: size)

        DispatchQueue.global().async {
            do {
                let data = try Data(contentsOf: url)
                let image = UIImage(data: data)
                completionHandler(image, nil)
            } catch {
                completionHandler(nil, error)
            }
        }

        return Int32(id) ?? 0
    }

    private func imageURL(with size: CGSize) -> URL {
        return size == .zero ? previewURL : staticThumbnailURL
    }

    func cancelImageRequest(_ requestID: WPMediaRequestID) {
        // Can't be canceled
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
        return created
    }

    func pixelSize() -> CGSize {
        return CGSize(width: largeGif.dims[0], height: largeGif.dims[1])
    }

    func utTypeIdentifier() -> String? {
        return String(kUTTypeGIF)
    }
}

// MARK: - ExportableAsset conformance

extension TenorMedia: ExportableAsset {
    var assetMediaType: MediaType {
        return .image
    }
}

// MARK: - MediaExternalAsset conformance
extension TenorMedia: MediaExternalAsset {
    var name: String {
        return title
    }

    var caption: String {
        return title
    }

    var URL: URL {
        return previewURL
    }
}
