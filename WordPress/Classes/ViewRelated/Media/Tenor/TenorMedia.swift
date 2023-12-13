import MobileCoreServices
import UniformTypeIdentifiers

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

extension TenorMedia: ExternalMediaAsset {
    var thumbnailURL: URL { images.staticThumbnailURL }
    var largeURL: URL { images.largeURL }
    var caption: String { "" }
    var assetMediaType: MediaType { .image }
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
