import WPMediaPicker


/// Data Source for Stock Photos
final class StockPhotosDataSource: NSObject, WPMediaCollectionDataSource {
    fileprivate static let paginationThreshold = 10

    fileprivate var photosMedia = [StockPhotosMedia]()
    var observers = [String: WPMediaChangesBlock]()
    private var dataLoader: StockPhotosDataLoader?

    private let throttle = Throttle(seconds: 1)


    init(service: StockPhotosService) {
        super.init()
        self.dataLoader = StockPhotosDataLoader(service: service, delegate: self)
    }

    func clearSearch(notifyObservers shouldNotify: Bool) {
        photosMedia.removeAll()
        if shouldNotify {
            notifyObservers()
        }
    }

    func numberOfGroups() -> Int {
        return 1
    }

    func search(for searchText: String?) {
        throttle.throttle { [weak self] in
            let params = StockPhotosSearchParams(text: searchText, pageable: StockPhotosPageable.initial())
            self?.search(params)
        }
    }

    private func search(_ params: StockPhotosSearchParams) {
        dataLoader?.search(params)
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
        fetchMoreContentIfNecessary(index)
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

    func searchCancelled() {
        clearSearch(notifyObservers: true)
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
//    private func notifyObservers() {
//        observers.forEach {
//            $0.value(false, IndexSet(), IndexSet(), IndexSet(), [])
//        }
//    }

    private func notifyObservers(incremental: Bool = false, inserted: IndexSet = IndexSet()) {
        observers.forEach {
            $0.value(incremental, IndexSet(), inserted, IndexSet(), [])
        }
    }
}

// MARK: - Pagination
extension StockPhotosDataSource {
    fileprivate func fetchMoreContentIfNecessary(_ index: Int) {
        if shoudLoadMore(index) {
            dataLoader?.loadNextPage()
        }
    }

    private func shoudLoadMore(_ index: Int) -> Bool {
        return index + type(of: self).paginationThreshold >= numberOfAssets()
    }
}

extension StockPhotosDataSource: StockPhotosDataLoaderDelegate {
    func didLoad(media: [StockPhotosMedia]) {
        photosMedia.append(contentsOf: media)
        notifyObservers()
    }
}
