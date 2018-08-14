/// Encapsulates search parameters (text, pagination, etc)
struct StockPhotosSearchParams {
    let text: String
    let pageable: Pageable?

    init(text: String?, pageable: Pageable?) {
        self.text = text ?? ""
        self.pageable = pageable
    }
}

/// Abstracts the service used to fetch Stock Photos
protocol StockPhotosService {
    func search(params: StockPhotosSearchParams, completion: @escaping (StockPhotosResultsPage) -> Void)
}
