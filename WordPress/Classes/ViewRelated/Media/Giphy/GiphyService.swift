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
}
    }
