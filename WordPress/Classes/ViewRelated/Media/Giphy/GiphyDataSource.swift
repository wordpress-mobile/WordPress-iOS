import WPMediaPicker


/// Data Source for Giphy
final class GiphyDataSource: NSObject, WPMediaCollectionDataSource {

    var observers = [String: WPMediaChangesBlock]()

    private(set) var searchQuery: String = ""

    func numberOfGroups() -> Int {
        return 1
    }

    func group(at index: Int) -> WPMediaGroup {
        return GiphyMediaGroup()
    }

    func selectedGroup() -> WPMediaGroup? {
        return GiphyMediaGroup()
    }

    func numberOfAssets() -> Int {
        return 0
    }

    func media(at index: Int) -> WPMediaAsset {
        return GiphyMedia()
    }

    func media(withIdentifier identifier: String) -> WPMediaAsset? {
        return GiphyMedia()
    }

    func registerChangeObserverBlock(_ callback: @escaping WPMediaChangesBlock) -> NSObjectProtocol {
        let blockKey = UUID().uuidString
        observers[blockKey] = callback
        return blockKey as NSString
    }

    func unregisterChangeObserver(_ blockKey: NSObjectProtocol) {
        guard let key = blockKey as? String else {
            assertionFailure("blockKey must be of type String")
            return
        }
        observers.removeValue(forKey: key)
    }

    func loadData(with options: WPMediaLoadOptions, success successBlock: WPMediaSuccessBlock?, failure failureBlock: WPMediaFailureBlock? = nil) {
        successBlock?()
    }

    func mediaTypeFilter() -> WPMediaType {
        return .image
    }

    func ascendingOrdering() -> Bool {
        return true
    }

    // MARK: Unused protocol methods

    func setSelectedGroup(_ group: WPMediaGroup) {
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

    func setAscendingOrdering(_ ascending: Bool) {
        //
    }
}
