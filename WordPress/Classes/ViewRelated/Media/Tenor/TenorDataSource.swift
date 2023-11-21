import Foundation

/// Data Source for Tenor
final class TenorDataSource: ExternalMediaDataSource {
    private(set) var assets: [ExternalMediaAsset] = []

    fileprivate static let paginationThreshold = 10

    private var dataLoader: TenorDataLoader?

    var onUpdatedAssets: (() -> Void)?
    var onStartLoading: (() -> Void)?
    var onStopLoading: (() -> Void)?

    private let scheduler = Scheduler(seconds: 0.5)

    private(set) var searchQuery: String = ""

    init(service: TenorService) {
        self.dataLoader = TenorDataLoader(service: service, delegate: self)
    }

    func search(for searchText: String) {
        searchQuery = searchText

        guard searchQuery.count > 1 else {
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

// MARK: - Pagination

extension TenorDataSource: TenorDataLoaderDelegate {
    func didLoad(media: [TenorMedia], reset: Bool) {
        defer {
            onStopLoading?()
        }

        guard media.count > 0, searchQuery.count > 0 else {
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
