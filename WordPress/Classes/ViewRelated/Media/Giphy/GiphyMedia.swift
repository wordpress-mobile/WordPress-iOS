import WPMediaPicker
import MobileCoreServices

struct GiphyImageCollection {
    private(set) var largeURL: URL
    private(set) var previewURL: URL
    private(set) var staticThumbnailURL: URL
    private(set) var largeSize: CGSize
}

/// Models a Giphy image
///
final class GiphyMedia: NSObject {
    private(set) var id: String
    private(set) var name: String
    private(set) var caption: String
    private let updatedDate: Date
    private let images: GiphyImageCollection

    init(id: String, name: String, caption: String, images: GiphyImageCollection, date: Date? = nil) {
        self.id = id
        self.name = name
        self.caption = caption
        self.updatedDate = date ?? Date()
        self.images = images
    }
}

extension GiphyMedia: WPMediaAsset {
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

        // Giphy API doesn't return a numerical ID value
        return 0
    }

    private func imageURL(with size: CGSize) -> URL {
        return size == .zero ? images.previewURL : images.staticThumbnailURL
    }

    func cancelImageRequest(_ requestID: WPMediaRequestID) {
        // Can't be cancelled
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
        return updatedDate
    }

    func pixelSize() -> CGSize {
        return images.largeSize
    }

    func utTypeIdentifier() -> String? {
        return String(kUTTypeGIF)
    }
}

// MARK: - ExportableAsset conformance

extension GiphyMedia: ExportableAsset {
    var assetMediaType: MediaType {
        return .image
    }
}

//// MARK: - MediaExternalAsset conformance
//
extension GiphyMedia: MediaExternalAsset {
    var URL: URL {
        return images.previewURL
    }
}
