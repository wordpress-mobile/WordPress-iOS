/// Implementations of this protocol will be notified when data is loaded from the TenorService
protocol TenorDataLoaderDelegate: AnyObject {
    func didLoad(media: [TenorMedia], reset: Bool)
}

/// Uses the TenorService to load GIFs, handling pagination
final class TenorDataLoader {
    private let service: TenorService
    private var request: TenorSearchParams?

    private weak var delegate: TenorDataLoaderDelegate?

    fileprivate enum State {
        case loading
        case idle
    }

    fileprivate var state: State = .idle

    init(service: TenorService, delegate: TenorDataLoaderDelegate) {
        self.service = service
        self.delegate = delegate
    }

    func search(_ params: TenorSearchParams) {
        request = params
        let isFirstPage = request?.pageable?.pageIndex == TenorPageable.defaultPageIndex
        state = .loading
        DispatchQueue.main.async { [weak self] in
            WPAnalytics.track(.tenorSearched)
            self?.service.search(params: params) { resultsPage in
                self?.state = .idle
                self?.request = TenorSearchParams(text: self?.request?.text, pageable: resultsPage.nextPageable())

                if let content = resultsPage.content() {
                    self?.delegate?.didLoad(media: content, reset: isFirstPage)
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
        guard let request = request else {
            return
        }

        // Bail out if we do not expect more pages of data
        guard request.pageable?.next() != nil else {
            return
        }

        search(request)
    }
}
