struct ReaderTabItem: FilterTabBarItem {

    let title: String
    let shouldHideButtonsView: Bool
    private(set) var topic: ReaderAbstractTopic?

    var accessibilityIdentifier: String {
        return title
    }

    /// initialize with topic
    init(topic: ReaderAbstractTopic) {
        self.topic = topic
        self.title = ReaderHelpers.displayTitle(for: topic)
        self.shouldHideButtonsView = !ReaderHelpers.topicIsFollowing(topic)
    }

    /// initialize with no topic
    init(title: String) {
        self.title = title
        self.shouldHideButtonsView = true
    }
}
