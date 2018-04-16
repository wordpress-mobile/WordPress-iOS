protocol StockPhotosDataLoaderDelegate: class {
    func didLoad(media: [StockPhotosMedia])
}


final class StockPhotosDataLoader {
    private let service: StockPhotosService
    private weak var delegate: StockPhotosDataLoaderDelegate?
    private var request: StockPhotosSearchParams?


    init(service: StockPhotosService, delegate: StockPhotosDataLoaderDelegate) {
        self.service = service
        self.delegate = delegate
    }

    func search(_ params: StockPhotosSearchParams) {
        request = params
        //state = .loading
        DispatchQueue.main.async { [weak self] in
            self?.service.search(params: params) { resultsPage in
//                self?.state = .idle
//                self?.pageable = resultsPage.nextPageable()
                self?.request = StockPhotosSearchParams(text: self?.request?.text, pageable: resultsPage.nextPageable())

                if let content = resultsPage.content() {
                    self?.delegate?.didLoad(media: content)
                }
            }
        }
    }

    func loadNextPage() {
        guard let request = request else {
            return
        }

        guard request.pageable != nil else {
            return
        }

        search(request)
    }
}
