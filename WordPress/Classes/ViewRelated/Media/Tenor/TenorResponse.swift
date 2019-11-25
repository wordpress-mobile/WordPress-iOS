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
    let title: String

    // Data format in the response has unnecessary depth. We'll convert it to a more optimal format
    var variants: [TenorGifFormat: TenorGif]

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: CodingKeys.id)

        let createdDate = try container.decode(Float.self, forKey: CodingKeys.created)
        created = Date(timeIntervalSince1970: Double(createdDate))

        title = try container.decode(String.self, forKey: CodingKeys.title)

        // Media field contains the media in several formats (gif, mp4, webm. in different sizes)
        // Its content is wrapped in an additional single element json array. We need to get that first.
        var mediaOuterContainer = try container.nestedUnkeyedContainer(forKey: CodingKeys.media)

        // We only need the ones in gif format
        variants = [TenorGifFormat: TenorGif]()

        // Get the inner container that contains the media in all the available formats
        let mediaContainer = try mediaOuterContainer.nestedContainer(keyedBy: MediaCodingKeys.self)

        // Selectively parse the media in .gif format
        for key in MediaCodingKeys.allCases {
            variants[key] = try mediaContainer.decode(TenorGif.self, forKey: key)
        }
    }
}

class TenorGif: NSObject, Codable {
    let url: String
    let dims: [Int]
    let preview: String
}

// MARK: - Helpers needed by WPMediaAsset conformance

extension TenorMedia {

    // If the media doesn't contain the required gifs for some reason, we have to ignore them
    var isValid: Bool {
        return previewGif != nil && largeGif != nil
    }

    var previewGif: TenorGif? {
        return variants[.tinygif]
    }

    var largeGif: TenorGif? {
        return variants[.gif]
    }

    var previewURL: URL? {
        guard let url = previewGif?.url else {
            return nil
        }
        return Foundation.URL(string: url)
    }

    var staticThumbnailURL: URL? {
        guard let url = previewGif?.preview else {
            return nil
        }
        return Foundation.URL(string: url)
    }
}

// MARK: - WPMediaAsset conformance

extension TenorMedia: WPMediaAsset {
    func image(with size: CGSize, completionHandler: @escaping WPMediaImageBlock) -> WPMediaRequestID {

        guard let url = imageURL(with: size) else {
            let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: nil)
            completionHandler(nil, error)
            return 0
        }

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

    private func imageURL(with size: CGSize) -> URL? {
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
        return CGSize(width: largeGif?.dims[0] ?? 0, height: largeGif?.dims[1] ?? 0)
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
        // This unwrap must be done in order to conform to the protocol.
        // It's %100 safe because we'll filter out the items that doesn't have a preview URL from the result set
        return previewURL!
    }
}
