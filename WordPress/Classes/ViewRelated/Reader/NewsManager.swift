/// Abstracts the business logic supporting the New Card
protocol NewsManager {
    func dismiss()
    func readMore()
    func shouldPresentCard(contextId: Identifier) -> Bool
    func didPresentCard()
    func load(then completion: @escaping (Result<NewsItem>) -> Void)
}

protocol NewsManagerDelegate: class {
    func didDismissNews()
}
