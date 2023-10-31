@testable import WordPress

final class MockStockPhotosService: StockPhotosService {
    private let mediaCount: Int

    init(mediaCount: Int) {
        self.mediaCount = mediaCount
    }

    func search(params: StockPhotosSearchParams, completion: @escaping (StockPhotosResultsPage) -> Void) {
        let text = params.text
        guard text.count > 0 else {
            completion(StockPhotosResultsPage.empty())
            return
        }
        DispatchQueue.global().async {
            let mediaResult = (1...self.mediaCount).map { self.crateStockPhotosMedia(id: "\($0)") }
            DispatchQueue.main.async {
                let page = StockPhotosResultsPage(results: mediaResult, pageable: nil)
                completion(page)
            }
        }
    }

    private func crateStockPhotosMedia(id: String) -> StockPhotosMedia {
        let url = "https://images.pexels.com/photos/710916/pexels-photo-710916.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940".toURL()!
        let thumbs = ThumbnailCollection(
            largeURL: "https://images.pexels.com/photos/710916/pexels-photo-710916.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940".toURL()!,
            mediumURL: "https://images.pexels.com/photos/710916/pexels-photo-710916.jpeg?auto=compress&cs=tinysrgb&h=350".toURL()!,
            postThumbnailURL: "https://images.pexels.com/photos/710916/pexels-photo-710916.jpeg?auto=compress&cs=tinysrgb&h=130".toURL()!,
            thumbnailURL: "https://images.pexels.com/photos/710916/pexels-photo-710916.jpeg?auto=compress&cs=tinysrgb&fit=crop&h=200&w=280".toURL()!
        )
        return StockPhotosMedia(
            id: id,
            URL: url,
            title: "pexels-photo-710916.jpeg",
            name: "pexels-photo-710916.jpeg",
            caption: "From Pexels",
            size:
            CGSize(width: 1880, height: 1253),
            thumbnails: thumbs
        )
    }
}

private extension String {
    func toURL() -> URL? {
        return URL(string: self)
    }
}
