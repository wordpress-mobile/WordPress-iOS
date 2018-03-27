import WPMediaPicker

final class StockPhotosMediaGroup: NSObject, WPMediaGroup {
    func name() -> String {
        return "group"
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

final class StockPhotosMedia: NSObject, WPMediaAsset {
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
        return ""
    }

    func identifier() -> String {
        return "image"
    }

    func date() -> Date {
        return Date()
    }

    func pixelSize() -> CGSize {
        return .zero
    }
}

final class StockPhotosDataSource: NSObject, WPMediaCollectionDataSource {
    func numberOfGroups() -> Int {
        return 1
    }

    func group(at index: Int) -> WPMediaGroup {
        return StockPhotosMediaGroup()
    }

    func selectedGroup() -> WPMediaGroup? {
        return nil
    }

    func setSelectedGroup(_ group: WPMediaGroup) {
        //
    }

    func numberOfAssets() -> Int {
        return 10
    }

    func media(at index: Int) -> WPMediaAsset {
        return StockPhotosMedia()
    }

    func media(withIdentifier identifier: String) -> WPMediaAsset? {
        return nil
    }

    func registerChangeObserverBlock(_ callback: @escaping WPMediaChangesBlock) -> NSObjectProtocol {
        //
        return NSObject()
    }

    func unregisterChangeObserver(_ blockKey: NSObjectProtocol) {
        //
    }

    func loadData(with options: WPMediaLoadOptions, success successBlock: WPMediaSuccessBlock?, failure failureBlock: WPMediaFailureBlock? = nil) {
        //
    }

    func add(_ image: UIImage, metadata: [AnyHashable: Any]?, completionBlock: WPMediaAddedBlock? = nil) {
        //
    }

    func addVideo(from url: URL, completionBlock: WPMediaAddedBlock? = nil) {
        //
    }

    func setMediaTypeFilter(_ filter: WPMediaType) {
        //
    }

    func mediaTypeFilter() -> WPMediaType {
        return .image
    }

    func setAscendingOrdering(_ ascending: Bool) {
        //
    }

    func ascendingOrdering() -> Bool {
        return true
    }
}
