/// Bootstraps a news card specific for the reader.
final class ReaderNewsCard {
    private let fileName = "News"
    private let tracksOrigin = "reader"

    func newsCard(containerIdentifier: Identifier, header: ReaderStreamViewController.ReaderHeader?, container: UIViewController, delegate: NewsManagerDelegate) -> UIView? {
        let database = UserDefaults.standard
        let stats = TracksNewsStats(origin: tracksOrigin)
        let newsManager = DefaultNewsManager(service: LocalNewsService(fileName: fileName), database: database, stats: stats, delegate: delegate)

        // News card should not be presented: return configured stream header
        guard newsManager.shouldPresentCard(contextId: containerIdentifier) else {
            return header
        }

        let newsCard = NewsCard(manager: newsManager)
        let news = News(manager: newsManager, ui: newsCard)

        // The news card is not available: return configured stream header
        guard let cardUI = news.card(containerId: containerIdentifier)?.view else {
            return header
        }

        container.addChildViewController(newsCard)

        // This stream does not have a header: return news card
        guard let sectionHeader = header else {
            return cardUI
        }

        // Return NewsCard and header
        let stackView = UIStackView(arrangedSubviews: [cardUI, sectionHeader])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }
}
