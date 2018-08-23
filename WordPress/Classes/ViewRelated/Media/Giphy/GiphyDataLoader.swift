/// Implementations of this protocol will be notified when data is loaded from the GiphyService
protocol GiphyDataLoaderDelegate: class {
    func didLoad(media: [GiphyMedia], reset: Bool)
}

/// Uses the GiphyService to load GIFs, handling pagination
final class GiphyDataLoader {
    private let service: GiphyService
    private var request: GiphySearchParams?

    private weak var delegate: GiphyDataLoaderDelegate?

    fileprivate enum State {
        case loading
        case idle
    }

    fileprivate var state: State = .idle

    init(service: GiphyService, delegate: GiphyDataLoaderDelegate) {
        self.service = service
        self.delegate = delegate
    }

    func search(_ params: GiphySearchParams) {
        request = params
        let isFirstPage = request?.pageable?.pageIndex == GiphyPageable.defaultPageIndex
        state = .loading
        DispatchQueue.main.async { [weak self] in
            // TODO: Add Analytics
            self?.service.search(params: params) { resultsPage in
                self?.state = .idle
                self?.request = GiphySearchParams(text: self?.request?.text, pageable: resultsPage.nextPageable())

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
