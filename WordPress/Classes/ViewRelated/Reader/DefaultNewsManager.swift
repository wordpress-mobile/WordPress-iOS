/// Default implementation of the NewsManager protocol
final class DefaultNewsManager: NewsManager {
    private let service: NewsService

    init(service: NewsService) {
        self.service = service
    }

    func dismiss() {
    }

    func readMore() {
    }

    func shouldPresentCard() -> Bool {
        return true
    }

    func load(then completion: @escaping (Result<NewsItem>) -> Void) {
        service.load { newsItem in
            completion(newsItem)
        }
    }
}
