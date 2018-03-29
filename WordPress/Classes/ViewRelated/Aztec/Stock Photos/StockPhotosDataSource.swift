import WPMediaPicker


/// Data Source for Stock Photos
final class StockPhotosDataSource: NSObject, WPMediaCollectionDataSource {

    var photosMedia = [StockPhotosMedia]()
    var observers = [String: WPMediaChangesBlock]()
    let service: StockPhotosService

    init(service: StockPhotosService) {
        self.service = service
        super.init()
    }

    func numberOfGroups() -> Int {
        return 1
    }

    func search(for searchText: String?) {
        let params = StockPhotosSearchParams(text: searchText ?? "")
        service.search(params: params) { (result) in
            self.searchCompleted(result: result)
        }
    }

    func group(at index: Int) -> WPMediaGroup {
        return StockPhotosMediaGroup()
    }

    func selectedGroup() -> WPMediaGroup? {
        return StockPhotosMediaGroup()
    }

    func numberOfAssets() -> Int {
        return photosMedia.count
    }

    func media(at index: Int) -> WPMediaAsset {
        return photosMedia[index]
    }

    func media(withIdentifier identifier: String) -> WPMediaAsset? {
        return photosMedia.filter { $0.identifier() == identifier }.first
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

    // MARK: Unnused protocol methods

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

// MARK: - Helpers

extension StockPhotosDataSource {
    private func searchCompleted(result: [StockPhotosMedia]) {
        self.photosMedia = result
        self.notifyObservers()
    }

    private func notifyObservers() {
        observers.forEach {
            $0.value(false, IndexSet(), IndexSet(), IndexSet(), [])
        }
    }
}
