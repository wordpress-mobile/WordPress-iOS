import MobileCoreServices
import WPMediaPicker

struct TenorImageCollection {
    let largeURL: URL
    let previewURL: URL
    let staticThumbnailURL: URL
    let largeSize: CGSize
}

// Models a Tenor image

final class TenorMedia: NSObject {
    let id: String
    let name: String
    let updatedDate: Date
    let images: TenorImageCollection

    init(id: String, name: String, images: TenorImageCollection, date: Date? = nil) {
        self.id = id
        self.name = name
        self.updatedDate = date ?? Date()
        self.images = images
    }
}

// MARK: - Create Tenor media from API GIF Entity

extension TenorMedia {
    convenience init?(tenorGIF gif: TenorGIF) {
        let largeGif = gif.media.first { $0.gif != nil }?.gif
        let previewGif = gif.media.first { $0.tinyGIF != nil }?.tinyGIF
        let thumbnailGif = gif.media.first { $0.nanoGIF != nil }?.nanoGIF

        guard let largeURL = largeGif?.url,
            let previewURL = previewGif?.url,
            let staticThumbnailURL = thumbnailGif?.url,
            let largeSize = largeGif?.mediaSize else {
            return nil
        }

        let images = TenorImageCollection(largeURL: largeURL,
                                          previewURL: previewURL,
                                          staticThumbnailURL: staticThumbnailURL,
                                          largeSize: largeSize)

        self.init(id: gif.id, name: gif.title ?? "", images: images, date: gif.created)
    }
}

// MARK: - WPMediaAsset

extension TenorMedia: WPMediaAsset {
    func image(with size: CGSize, completionHandler: @escaping WPMediaImageBlock) -> WPMediaRequestID {
        // We don't need to download any image here, leave it for the overlay to handle
        return 0
    }

    func cancelImageRequest(_ requestID: WPMediaRequestID) {
        // Nothing to do
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

extension TenorMedia: ExportableAsset {
    var assetMediaType: MediaType {
        return .image
    }
}

// MARK: - MediaExternalAsset conformance

extension TenorMedia: MediaExternalAsset {
    // The URL source for saving into user's media library as well as GIF preview
    var URL: URL {
        return images.largeURL
    }

    var caption: String {
        return ""
    }
}

// Overlay
extension TenorMedia {
    // Return the smallest GIF size for previewing
    var previewURL: URL {
        return images.staticThumbnailURL
    }
}
