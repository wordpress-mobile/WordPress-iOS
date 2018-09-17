final class LocalNewsService: NewsService {
    private var content: [String: String]?

    /// This initialiser is here temporarily. Instead of the content, we should only pass the url to the file that we want to load
    init(filePath: String?) {
        loadFile(path: filePath)
    }

    private func loadFile(path: String?) {
        guard let path = path else {
            return
        }

        content = NSDictionary.init(contentsOfFile: path) as? [String: String]
    }

    func load(then completion: @escaping (Result<NewsItem>) -> Void) {
        guard let content = content else {
            let result: Result<NewsItem> = .error(NewsError.fileNotFound)
            completion(result)

            return
        }

        guard let newsItem = NewsItem(fileContent: content) else {
            let result: Result<NewsItem> = .error(NewsError.invalidContent)
            completion(result)

            return
        }

        let result: Result = .success(newsItem)
        completion(result)
    }
}
