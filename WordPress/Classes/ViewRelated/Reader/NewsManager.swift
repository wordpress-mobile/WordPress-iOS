/// Abstracts the business logic supporting the New Card
protocol NewsManager {
    func dismiss()
    func load(then completion: @escaping (Result<NewsItem>) -> Void)
}
