/// Puts together the implementation of the News Card
final class News {
    private let manager: NewsManager
    private let ui: NewsCard

    init(manager: NewsManager, ui: NewsCard) {
        self.manager = manager
        self.ui = ui
    }

    func card(containerId: Identifier) -> NewsCard? {
        guard manager.shouldPresentCard(containerId: containerId) else {
            return nil
        }

        return ui
    }
}
