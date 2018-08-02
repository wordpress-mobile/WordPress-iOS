/// Abstracts the business logic supporting the New Card
protocol NewsManager {
    func dismiss()
    func shouldPresentCard() -> Bool
    func load(then completion: @escaping (Result<NewsItem>) -> Void)
}
