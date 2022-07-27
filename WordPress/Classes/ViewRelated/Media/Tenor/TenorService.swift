/// Encapsulates search parameters (text, pagination, etc)
struct TenorSearchParams {
    let text: String
    let pageable: Pageable?
    let limit: Int

    init(text: String?, pageable: Pageable?) {
        self.text = text ?? ""
        self.pageable = pageable
        self.limit = pageable != nil ? pageable!.pageSize : TenorPageable.defaultPageSize
    }
}

class TenorService {
    static let tenor: TenorClient = {
        TenorClient.configure(apiKey: ApiCredentials.tenorApiKey)
        return TenorClient.shared
    }()

    func search(params: TenorSearchParams, completion: @escaping (TenorResultsPage) -> Void) {
        let tenorPageable = params.pageable as? TenorPageable
        let currentPageIndex = tenorPageable?.pageIndex

        TenorService.tenor.search(for: params.text,
                                  limit: params.limit,
                                  from: tenorPageable?.position) { gifs, position, error in

            guard let gifObjects = gifs, error == nil else {
                completion(TenorResultsPage.empty())
                return
            }

            let medias = gifObjects.compactMap { TenorMedia(tenorGIF: $0) }
            let nextPageable = TenorPageable(itemsPerPage: params.limit,
                                             position: position,
                                             currentPageIndex: currentPageIndex ?? 0)
            let result = TenorResultsPage(results: medias,
                                          pageable: nextPageable)
            completion(result)
        }
    }
}
