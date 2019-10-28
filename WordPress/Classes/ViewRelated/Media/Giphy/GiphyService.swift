/// Encapsulates search parameters (text, pagination, etc)
struct GiphySearchParams {
    let text: String
    let pageable: Pageable?

    init(text: String?, pageable: Pageable?) {
        self.text = text ?? ""
        self.pageable = pageable
    }
}

struct GiphyService {
    func search(params: GiphySearchParams, completion: @escaping (GiphyResultsPage) -> Void) {
        completion(GiphyResultsPage.empty())
    }
}



// Allows us to mock out the pagination in tests
protocol GPHPaginationType {
    /// Total Result Count.
    var totalCount: Int { get }

    /// Actual Result Count (not always == limit)
    var count: Int { get }

    /// Offset to start next set of results.
    var offset: Int { get }
}
