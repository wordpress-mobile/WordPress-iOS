import Gridicons

/// Encapsulates creating of a ReaderMenuItem for Discover
final class DiscoverMenuItemCreator: ReaderMenuItemCreator {
    func supports(_ topic: ReaderAbstractTopic) -> Bool {
        return ReaderHelpers.topicIsDiscover(topic)
    }

    func menuItem(with topic: ReaderAbstractTopic) -> ReaderMenuItem {
        var item = ReaderMenuItem(title: topic.title,
                                  type: .topic,
                                  icon: .gridicon(.mySites),
                                  topic: topic)
        item.order = ReaderDefaultMenuItemOrder.discover.rawValue

        return item
    }
}
