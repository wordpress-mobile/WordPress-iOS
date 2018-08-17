import WPMediaPicker

final class StockPhotosMediaGroup: NSObject, WPMediaGroup {
    func name() -> String {
        return String.freePhotosLibrary
    }

    func image(with size: CGSize, completionHandler: @escaping WPMediaImageBlock) -> WPMediaRequestID {
        return 0
    }

    func cancelImageRequest(_ requestID: WPMediaRequestID) {
        //
    }

    func baseGroup() -> Any {
        return ""
    }

    func identifier() -> String {
        return "group id"
    }

    func numberOfAssets(of mediaType: WPMediaType, completionHandler: WPMediaCountBlock? = nil) -> Int {
        return 10
    }
}
