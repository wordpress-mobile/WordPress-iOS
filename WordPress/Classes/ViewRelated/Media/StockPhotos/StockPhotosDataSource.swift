import Foundation

/// Data Source for Stock Photos
final class StockPhotosDataSource: ExternalMediaDataSource {
    private(set) var assets = [ExternalMediaAsset]()

    private var dataLoader: StockPhotosDataLoader?

    var onUpdatedAssets: (() -> Void)?
    var onStartLoading: (() -> Void)?
    var onStopLoading: (() -> Void)?

    private let scheduler = Scheduler(seconds: 0.5)

    private(set) var searchQuery: String = ""

    init(service: StockPhotosService) {
        self.dataLoader = StockPhotosDataLoader(service: service, delegate: self)
    }

    func search(for searchText: String) {
        searchQuery = searchText

        guard searchText.count > 1 else {
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

    private func clearSearch(notifyObservers shouldNotify: Bool) {
        assets.removeAll()
        if shouldNotify {
            onUpdatedAssets?()
        }
    }

    func loadMore() {
        dataLoader?.loadNextPage()
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

        assert(Thread.isMainThread)
        if reset {
            self.assets = media
        } else {
            self.assets += media
        }
        onUpdatedAssets?()
    }
}
