import WPMediaPicker


/// Data Source for Stock Photos
final class StockPhotosDataSource: NSObject, WPMediaCollectionDataSource {
    func numberOfGroups() -> Int {
        print("==== number of groups ====")
        return 1
    }

    func group(at index: Int) -> WPMediaGroup {
        return StockPhotosMediaGroup()
    }

    func selectedGroup() -> WPMediaGroup? {
        return StockPhotosMediaGroup()
    }

    func setSelectedGroup(_ group: WPMediaGroup) {
        //
    }

    func numberOfAssets() -> Int {
        print("==== number of assets ===")
        return 0
    }

    func media(at index: Int) -> WPMediaAsset {
        return StockPhotosMedia()
    }

    func media(withIdentifier identifier: String) -> WPMediaAsset? {
        return StockPhotosMedia()
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
