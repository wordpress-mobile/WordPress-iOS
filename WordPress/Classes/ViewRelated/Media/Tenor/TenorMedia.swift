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

        guard largeGif != nil, previewGif != nil, thumbnailGif != nil else {
            return nil
        }

        let images = TenorImageCollection(largeURL: largeGif!.url,
                                          previewURL: previewGif!.url,
                                          staticThumbnailURL: thumbnailGif!.url,
                                          largeSize: largeGif!.mediaSize)

        self.init(id: gif.id, name: gif.title ?? "", images: images, date: gif.created)
    }
}

// MARK: - WPMediaAsset

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

        return (id as NSString).intValue
    }

    private func imageURL(with size: CGSize) -> URL {
        return size == .zero ? images.previewURL : images.staticThumbnailURL
    }

    func cancelImageRequest(_ requestID: WPMediaRequestID) {}

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
