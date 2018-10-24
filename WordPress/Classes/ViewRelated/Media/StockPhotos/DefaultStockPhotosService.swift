/// Default implementation of the Stock Photos Service, attacking a blog's restful api
final class DefaultStockPhotosService: StockPhotosService {
    private let endPoint = "/rest/v1/meta/external-media/pexels"

    private struct Parameters {
        static let search = "search"
        static let resultsPerPage = "number"
        static let pageIndex = "page_handle"
    }

    private struct ParsingKeys {
        static let media = "media"
        static let meta = "meta"
    }

    private let api: WordPressComRestApi

    init(api: WordPressComRestApi) {
        self.api = api
    }

    func search(params: StockPhotosSearchParams, completion: @escaping (StockPhotosResultsPage) -> Void) {
        api.GET(endPoint, parameters: parameters(params: params), success: { results, response in
            if let media = results[ParsingKeys.media], let meta = results[ParsingKeys.meta] as? [String: Int] {
                do {
                    let mediaJSON = try JSONSerialization.data(withJSONObject: media as Any)
                    let parsedResponse = try JSONDecoder().decode([StockPhotosMedia].self, from: mediaJSON)

                    let metaJSON = try JSONSerialization.data(withJSONObject: meta as Any)
                    let parsedPageable = try JSONDecoder().decode(StockPhotosPageable.self, from: metaJSON)

                    let page = StockPhotosResultsPage(results: parsedResponse, pageable: parsedPageable)

                    completion(page)
                } catch {
                    // Not sure how to handle this
                    completion(StockPhotosResultsPage.empty())
                }
            }
        }) { error, response in
            // I am not sure how we are going to handle errors. In the meantime, I'm returning an empty result
            completion(StockPhotosResultsPage.empty())
        }
    }

    private func parameters(params: StockPhotosSearchParams) -> [String: AnyObject] {
        let text = params.text
        let pageSize = params.pageable?.pageSize ?? StockPhotosPageable.defaultPageSize
        let pageIndex = params.pageable?.pageIndex ?? StockPhotosPageable.defaultPageIndex

        return [Parameters.search: text as AnyObject,
                Parameters.resultsPerPage: pageSize as AnyObject,
                Parameters.pageIndex: pageIndex as AnyObject]
    }
}
