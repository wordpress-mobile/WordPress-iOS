
final class GiphyResultsPage: ResultsPage {
    private let results: [GiphyMedia]
    private let pageable: Pageable?

    init(results: [GiphyMedia], pageable: Pageable? = nil) {
        self.results = results
        self.pageable = pageable
    }

    func content() -> [GiphyMedia]? {
        return results
    }

    func nextPageable() -> Pageable? {
        return pageable?.next()
    }
}

extension GiphyResultsPage {
    static func empty() -> GiphyResultsPage {
        return GiphyResultsPage(results: [], pageable: nil)
    }
}
