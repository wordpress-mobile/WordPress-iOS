
import Foundation

protocol StockPhotosService {
    func search(text: String, completion: @escaping ([StockPhotosMedia]) -> Void)
}

final class DefaultStockPhotosService: StockPhotosService {
    private let endPoint = "/rest/v1/meta/external-media/pexels"

    private struct Parameters {
        static let search = "search"
    }

    private let api: WordPressComRestApi

    init(api: WordPressComRestApi) {
        self.api = api
    }

    func search(text: String, completion: @escaping ([StockPhotosMedia]) -> Void) {
        api.GET(endPoint, parameters: parameters(text: text), success: { something, response in
            print("========= success! ====")
            // success
        }) { error, response in
            // Fail!
            print("========= failure! ==== ", error)
            print("========= response! ==== ", response)
        }
        //StockPhotosServiceMock().search(text: text, completion: completion)
    }

    private func parameters(text: String) -> [String: AnyObject] {
        return [Parameters.search: text as AnyObject]
    }
}

// MARK: - Temporary mock for testing

final class StockPhotosServiceMock: StockPhotosService {
    func search(text: String, completion: @escaping ([StockPhotosMedia]) -> Void) {
        guard text.count > 0 else {
            completion([])
            return
        }
        DispatchQueue.global().async {
            let totalMedia = text.count
            let mediaResult = (1...totalMedia).map { self.crateStockPhotosMedia(id: $0 as Int) }
            DispatchQueue.main.async {
                completion(mediaResult)
            }
        }
    }

    private func crateStockPhotosMedia(id: Int) -> StockPhotosMedia {
        let url = "https://images.pexels.com/photos/710916/pexels-photo-710916.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940".toURL()!
        let thumbs = ThumbnailCollection(
            largeURL: "https://images.pexels.com/photos/710916/pexels-photo-710916.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940".toURL()!,
            mediumURL: "https://images.pexels.com/photos/710916/pexels-photo-710916.jpeg?auto=compress&cs=tinysrgb&h=350".toURL()!,
            postThumbnailURL: "https://images.pexels.com/photos/710916/pexels-photo-710916.jpeg?auto=compress&cs=tinysrgb&h=130".toURL()!,
            thumbnailURL: "https://images.pexels.com/photos/710916/pexels-photo-710916.jpeg?auto=compress&cs=tinysrgb&fit=crop&h=200&w=280".toURL()!
        )
        return StockPhotosMedia(
            id: id,
            guid: "\(id)",
            URL: url,
            title: "pexels-photo-710916.jpeg",
            name: "pexels-photo-710916.jpeg",
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
