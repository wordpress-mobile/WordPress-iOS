import WPMediaPicker
import MobileCoreServices

/// Models a Giphy image
/// Currently just stores a reference to a single size image
///
final class GiphyMedia: NSObject {
    private(set) var id: String
    private(set) var url: String
    private(set) var size: CGSize
    private let updatedDate: Date

    init(id: String, url: String, size: CGSize, date: Date? = nil) {
        self.id = id
        self.url = url
        self.size = size
        self.updatedDate = date ?? Date()
    }
}

extension GiphyMedia: WPMediaAsset {
    func image(with size: CGSize, completionHandler: @escaping WPMediaImageBlock) -> WPMediaRequestID {

        DispatchQueue.global().async {
            do {
                if let url = URL(string: self.url) {
                    let data = try Data(contentsOf: url)
                    let image = UIImage(data: data)
                    completionHandler(image, nil)
                } else {
                    completionHandler(nil, nil)
                }
            } catch {
                completionHandler(nil, error)
            }
        }

        // Giphy API doesn't return a numerical ID value
        return 0
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
        return size
    }

    func utTypeIdentifier() -> String? {
        return String(kUTTypeGIF)
    }
}
