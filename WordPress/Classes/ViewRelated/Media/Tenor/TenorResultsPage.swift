
final class TenorResultsPage: ResultsPage {
    private let results: [TenorMedia]
    private let pageable: Pageable?

    init(results: [TenorMedia], pageable: Pageable? = nil) {
        self.results = results
        self.pageable = pageable
    }

    func content() -> [TenorMedia]? {
        return results
    }

    func nextPageable() -> Pageable? {
        return pageable?.next()
    }
}

extension TenorResultsPage {
    static func empty() -> TenorResultsPage {
        return TenorResultsPage(results: [], pageable: nil)
    }
}
