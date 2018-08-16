import WPMediaPicker

/// Models a Giphy image
///
final class GiphyMedia: NSObject {
}

extension GiphyMedia: WPMediaAsset {
    func image(with size: CGSize, completionHandler: @escaping WPMediaImageBlock) -> WPMediaRequestID {
        return 0
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
        return ""
    }

    func date() -> Date {
        return Date()
    }

    func pixelSize() -> CGSize {
        return .zero
    }
}
