/// Bootstraps a news card specific for the reader.
final class ReaderNewsCard {
    private let fileName = "News"

    func newsCard(containerIdentifier: Identifier, header: ReaderStreamViewController.ReaderHeader?) -> UIView? {
        let database = UserDefaults.standard
        let newsManager = DefaultNewsManager(service: LocalNewsService(fileName: fileName), database: database)

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
