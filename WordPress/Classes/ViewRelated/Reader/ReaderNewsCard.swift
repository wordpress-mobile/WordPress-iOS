/// Bootstraps a news card specific for the reader.
final class ReaderNewsCard {
    private let fileName = "News"

    private lazy var newsManager: NewsManager = {
        let database = UserDefaults.standard
        let returnValue = DefaultNewsManager(service: LocalNewsService(fileName: fileName), database: database)

        return returnValue
    }()

    private lazy var newsCard: NewsCard = {
        return NewsCard(manager: self.newsManager)
    }()

    func newsCard(containerIdentifier: Identifier, header: ReaderStreamViewController.ReaderHeader?, container: UIViewController) -> UIView? {
        // News card should not be presented: return configured stream header
        guard newsManager.shouldPresentCard(contextId: containerIdentifier) else {
            return header
        }

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
