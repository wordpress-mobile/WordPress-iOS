final class LocalNewsService: NewsService {
    private let fileName: String


    /// This initialiser is here temporarily. Instead of the content, we should only pass the url to the file that we want to load
    init(fileName: String) {
        self.fileName = fileName
    }

    func load(then completion: @escaping (Result<NewsItem>) -> Void) {
        let newsItem = NewsItem(title: "A title", content: fileName, extendedInfoURL: URL(string: "")!)
        let result: Result = .success(newsItem)
        completion(result)
    }
}
