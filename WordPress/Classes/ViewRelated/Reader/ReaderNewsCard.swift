/// Bootstraps a news card specific for the reader.
final class ReaderNewsCard {
    private let fileName = "News"
    private let tracksOrigin = "reader"

    private lazy var database = {
        return UserDefaults.standard
    }()

    private lazy var stats = {
        return TracksNewsStats(origin: tracksOrigin)
    }()

    private lazy var newsManager: DefaultNewsManager = {
        let localFilePath = Bundle.main.path(forResource: fileName, ofType: "strings")
        return DefaultNewsManager(service: LocalNewsService(filePath: localFilePath), database: self.database, stats: self.stats)
    }()

    func shouldPresentCard(containerIdentifier: Identifier) -> Bool {
        return newsManager.shouldPresentCard(contextId: containerIdentifier)
    }

    func newsCard(containerIdentifier: Identifier, header: ReaderStreamViewController.ReaderHeader?, container: UIViewController, delegate: NewsManagerDelegate) -> UIView? {

        //Set up the delegate, otherwise the actions associated to the buttons in the news card will not be triggered
        newsManager.delegate = delegate

        // News card should not be presented: return configured stream header
        guard shouldPresentCard(containerIdentifier: containerIdentifier) else {
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
