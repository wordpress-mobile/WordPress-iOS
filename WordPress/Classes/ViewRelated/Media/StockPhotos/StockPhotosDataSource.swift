import WPMediaPicker


/// Data Source for Stock Photos
final class StockPhotosDataSource: NSObject, WPMediaCollectionDataSource {
    fileprivate static let paginationThreshold = 10

    fileprivate var photosMedia = [StockPhotosMedia]()
    var observers = [String: WPMediaChangesBlock]()
    private var dataLoader: StockPhotosDataLoader?

    var onStartLoading: (() -> Void)?
    var onStopLoading: (() -> Void)?

    private let scheduler = Scheduler(seconds: 0.5)

    private(set) var searchQuery: String = ""

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
        searchQuery = searchText ?? ""

        guard searchText?.isEmpty == false else {
            clearSearch(notifyObservers: true)
            scheduler.cancel()
            return
        }

        scheduler.debounce { [weak self] in
            let params = StockPhotosSearchParams(text: searchText, pageable: StockPhotosPageable.first())
            self?.search(params)
            self?.onStartLoading?()
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

    func registerGroupChangeObserverBlock(_ callback: @escaping WPMediaGroupChangesBlock) -> NSObjectProtocol {
        // The group never changes
        return NSNull()
    }

    func unregisterGroupChangeObserver(_ blockKey: NSObjectProtocol) {
        // The group never changes
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
        searchQuery = ""
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
    func didLoad(media: [StockPhotosMedia], reset: Bool) {
        defer {
            onStopLoading?()
        }

        guard media.count > 0 && searchQuery.count > 0 else {
            clearSearch(notifyObservers: true)
            return
        }

        if reset {
            overwriteMedia(with: media)
        } else {
            appendMedia(with: media)
        }
    }

    private func overwriteMedia(with media: [StockPhotosMedia]) {
        photosMedia = media
        notifyObservers(incremental: false)
    }

    private func appendMedia(with media: [StockPhotosMedia]) {
        let currentMaxIndex = photosMedia.count
        let newMaxIndex = currentMaxIndex + media.count - 1

        let isIncremental = currentMaxIndex != 0
        let insertedIndexes = IndexSet(integersIn: currentMaxIndex...newMaxIndex)

        photosMedia.append(contentsOf: media)
        notifyObservers(incremental: isIncremental, inserted: insertedIndexes)
    }
}
