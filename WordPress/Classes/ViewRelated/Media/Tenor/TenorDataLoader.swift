// Implementations of this protocol will be notified when data is loaded from the TenorService
protocol TenorDataLoaderDelegate: class {
    func didLoad(media: [TenorMedia], reset: Bool)
}

// Uses the TenorService to load GIFs, handling pagination
class TenorDataLoader {
    private let service: TenorService
    private var searchParamsToUseNext: TenorSearchParams?

    private weak var delegate: TenorDataLoaderDelegate?

    private enum State {
        case loading
        case idle
    }

    private var state: State = .idle

    init(service: TenorService, delegate: TenorDataLoaderDelegate) {
        self.service = service
        self.delegate = delegate
    }

    func search(_ params: TenorSearchParams) {
        searchParamsToUseNext = params
        let isFirstPage = searchParamsToUseNext?.pageable?.pageIndex == TenorPageable.defaultPageIndex
        state = .loading
        DispatchQueue.main.async { [weak self] in
            #warning("TODO: Needs to be changed in WordpressShared")
            WPAnalytics.track(.giphySearched)

            self?.service.search(params: params) { [weak self] resultsPage in
                guard let self = self else { return }

                self.state = .idle
                self.searchParamsToUseNext = TenorSearchParams(text: self.searchParamsToUseNext?.text, pageable: resultsPage.nextPageable())

                if let content = resultsPage.content() {
                    self.delegate?.didLoad(media: content, reset: isFirstPage)
                }
            }
        }
    }

    func loadNextPage() {
        // Bail out if there is another active request
        guard state == .idle else {
            return
        }

        // Bail out if we are not aware of the pagination status
        guard let searchParamsToUseNext = searchParamsToUseNext else {
            return
        }

        // Bail out if we do not expect more pages of data
        guard searchParamsToUseNext.pageable?.next() != nil else {
            return
        }

        search(searchParamsToUseNext)
    }
}
