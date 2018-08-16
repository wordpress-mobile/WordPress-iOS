/// Null implementation of the Stock Photos Service. This implementation will always return empty results
final class NullStockPhotosService: StockPhotosService {
    func search(params: StockPhotosSearchParams, completion: @escaping (StockPhotosResultsPage) -> Void) {
        let emptyPage = StockPhotosResultsPage.empty()
        completion(emptyPage)
    }
}
