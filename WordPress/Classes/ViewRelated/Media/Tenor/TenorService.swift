import Foundation

struct TenorSearchParams {
    let text: String
    let pageable: Pageable?

    init(text: String?, pageable: Pageable?) {
        self.text = text ?? ""
        self.pageable = pageable
    }
}

class TenorService {
    private let tenorClient = TenorClient()
    
    func search(params: TenorSearchParams, completion: @escaping (TenorResultsPage) -> Void) {
        let offset = params.pageable?.pageIndex ?? 0
        let pageSize = params.pageable?.pageSize ?? TenorPageable.defaultPageSize
        
        tenorClient.search(params.text, pos: offset, limit: pageSize) {[weak self] (result) in
            switch result {
            case .success(let response):
                let pageable = TenorPageable(nextOffset: Int(response.next) ?? 0)
                let resultsPage = TenorResultsPage(results: response.results, pageable: pageable)
                completion(resultsPage)
            case .failure(let error):
                DDLogDebug(error.localizedDescription)
                completion(TenorResultsPage.empty())
            }
        }
    }
}

