final class LocalNewsService: NewsService {
    private let content: String


    /// This initialiser is here temporarily. Instead of the content, we should only pass the url to the file that we want to load
    init(content: String) {
        self.content = content
    }

    func load(then completion: @escaping (Result<NewsItem>) -> Void) {
        let newsItem = NewsItem(content: content)
        let result: Result = .success(newsItem)
        completion(result)
    }
}
