
final class StockPhotosResultsPage: ResultsPage {
    private let results: [StockPhotosMedia]
    private let pageable: Pageable?

    init(results: [StockPhotosMedia], pageable: Pageable?) {
        self.results = results
        self.pageable = pageable
    }

    func content() -> [StockPhotosMedia]? {
        return results
    }

    func nextPageable() -> Pageable? {
        return pageable?.next()
    }
}

extension StockPhotosResultsPage {
    static func empty() -> StockPhotosResultsPage {
        return StockPhotosResultsPage(results: [], pageable: nil)
    }
}
