import MobileCoreServices
import WPMediaPicker

struct TenorImageCollection {
    private(set) var largeURL: URL
    private(set) var previewURL: URL
    private(set) var staticThumbnailURL: URL
    private(set) var largeSize: CGSize
}

// Models a Tenor image

final class TenorMedia: NSObject {
    private(set) var id: String
    private(set) var name: String
    private(set) var caption: String
    private let updatedDate: Date
    private let images: TenorImageCollection

    init(id: String, name: String, caption: String, images: TenorImageCollection, date: Date? = nil) {
        self.id = id
        self.name = name
        self.caption = caption
        self.updatedDate = date ?? Date()
        self.images = images
    }
}

// MARK: - Create Tenor media from API GIF Entity

extension TenorMedia {
    convenience init?(tenorGIF gif: TenorGIF) {
        let largeGif = gif.media.first { $0.gif != nil }?.gif
        let previewGif = gif.media.first { $0.tinyGIF != nil }?.tinyGIF

        guard largeGif != nil, previewGif != nil else {
            return nil
        }

        let images = TenorImageCollection(largeURL: largeGif!.url,
                                          previewURL: previewGif!.url,
                                          staticThumbnailURL: previewGif!.url,
                                          largeSize: largeGif!.mediaSize)

        self.init(id: gif.id, name: gif.title ?? "", caption: "", images: images, date: gif.created)
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

//
extension TenorMedia: MediaExternalAsset {
    var URL: URL {
        return images.previewURL
    }
}
