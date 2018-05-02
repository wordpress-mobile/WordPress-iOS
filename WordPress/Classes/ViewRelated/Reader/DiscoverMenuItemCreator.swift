import Gridicons

final class DiscoverMenuItemCreator: ReaderMenuItemCreator {
    func supports(_ topic: ReaderAbstractTopic) -> Bool {
        return ReaderHelpers.topicIsDiscover(topic)
    }

    func menuItem(with topic: ReaderAbstractTopic) -> ReaderMenuItem {
        var item = ReaderMenuItem(title: topic.title,
                                  type: .topic,
                                  icon: Gridicon.iconOfType(.mySites),
                                  topic: topic)
        item.order = ReaderDefaultMenuItemOrder.discover.rawValue

        return item
    }
}
