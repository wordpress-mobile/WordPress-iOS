/// Abstracts the business logic supporting the New Card
protocol NewsManager {
    func dismiss()
    func readMore()
    func shouldPresentCard(contextId: Identifier) -> Bool
    func load(then completion: @escaping (Result<NewsItem>) -> Void)
}
