/// Abstracts a source of News (i.e. the source of content for the New Card)
protocol NewsService {
    func load(then completion: @escaping (Result<NewsItem, Error>) -> Void)
}

enum NewsError: Error {
    case fileNotFound
    case invalidContent
}
