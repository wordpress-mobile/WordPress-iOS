protocol StockPhotosDataLoaderDelegate: class {
    func didLoad(media: [StockPhotosMedia])
}


final class StockPhotosDataLoader {
    private let service: StockPhotosService
    private weak var delegate: StockPhotosDataLoaderDelegate?


    init(service: StockPhotosService, delegate: StockPhotosDataLoaderDelegate) {
        self.service = service
        self.delegate = delegate
    }

    func search(_ params: StockPhotosSearchParams) {
        //state = .loading
        DispatchQueue.main.async { [weak self] in
            self?.service.search(params: params) { resultsPage in
//                self?.state = .idle
//                self?.pageable = resultsPage.nextPageable()

                if let content = resultsPage.content() {
                    self?.delegate?.didLoad(media: content)
                }
            }
        }
    }
}
