import WPMediaPicker

// Data Source for Tenor
class TenorDataSource: NSObject, WPMediaCollectionDataSource {
    private static let paginationThreshold = 10

    private var gifMedia = [TenorMedia]()
    private var dataLoader: TenorDataLoader?
    private let scheduler = Scheduler(seconds: 0.5)
    
    var observers = [String: WPMediaChangesBlock]()
    var onStartLoading: (() -> Void)?
    var onStopLoading: (() -> Void)?


    private(set) var searchQuery: String = ""

    init(service: TenorService) {
        super.init()
        self.dataLoader = TenorDataLoader(service: service, delegate: self)
    }

    func clearSearch(notifyObservers shouldNotify: Bool) {
        gifMedia.removeAll()
        if shouldNotify {
            notifyObservers()
        }
    }

    func search(for searchText: String?) {
        searchQuery = searchText ?? ""

        guard searchText?.isEmpty == false else {
            clearSearch(notifyObservers: true)
            scheduler.cancel()
            return
        }

        scheduler.debounce { [weak self] in
            let params = TenorSearchParams(text: searchText, pageable: TenorPageable.first())
            self?.search(params)
            self?.onStartLoading?()
        }
    }

    private func search(_ params: TenorSearchParams) {
        dataLoader?.search(params)
    }

    func numberOfGroups() -> Int {
        return 1
    }

    func group(at index: Int) -> WPMediaGroup {
        return TenorMediaGroup()
    }

    func selectedGroup() -> WPMediaGroup? {
        return TenorMediaGroup()
    }

    func numberOfAssets() -> Int {
        return gifMedia.count
    }

    func media(at index: Int) -> WPMediaAsset {
        fetchMoreContentIfNecessary(index)
        return gifMedia[index]
    }

    func media(withIdentifier identifier: String) -> WPMediaAsset? {
        return gifMedia.filter { $0.identifier() == identifier }.first
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


// MARK: - Helpers

extension TenorDataSource {
    private func notifyObservers(incremental: Bool = false, inserted: IndexSet = IndexSet()) {
        DispatchQueue.main.async {
            self.observers.forEach {
            $0.value(incremental, IndexSet(), inserted, IndexSet(), [])
            }
        }
    }
}

// MARK: - Pagination

extension TenorDataSource {
    fileprivate func fetchMoreContentIfNecessary(_ index: Int) {
        if shouldLoadMore(index) {
            dataLoader?.loadNextPage()
        }
    }

    private func shouldLoadMore(_ index: Int) -> Bool {
        return index + type(of: self).paginationThreshold >= numberOfAssets()
    }
}

extension TenorDataSource: TenorDataLoaderDelegate {
    func didLoad(media: [TenorMedia], reset: Bool) {
        defer {
            onStopLoading?()
        }

        guard searchQuery.count > 0 else {
            clearSearch(notifyObservers: true)
            return
        }

        if reset {
            overwriteMedia(with: media)
        } else if media.count > 0 {
            appendMedia(with: media)
        }
    }

    private func overwriteMedia(with media: [TenorMedia]) {
        gifMedia = media
        notifyObservers(incremental: false)
    }

    private func appendMedia(with media: [TenorMedia]) {
        let currentMaxIndex = gifMedia.count
        let newMaxIndex = currentMaxIndex + media.count - 1

        let isIncremental = currentMaxIndex != 0
        let insertedIndexes = IndexSet(integersIn: currentMaxIndex...newMaxIndex)

        gifMedia.append(contentsOf: media)
        notifyObservers(incremental: isIncremental, inserted: insertedIndexes)
    }
}
