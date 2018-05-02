import Gridicons

final class LikedMenuItemCreator: ReaderMenuItemCreator {
    func supports(_ topic: ReaderAbstractTopic) -> Bool {
        return ReaderHelpers.topicIsLiked(topic)
    }

    func menuItem(with topic: ReaderAbstractTopic) -> ReaderMenuItem {
        var item = ReaderMenuItem(title: topic.title,
                                  type: .topic,
                                  icon: Gridicon.iconOfType(.star),
                                  topic: topic)
        item.order = ReaderDefaultMenuItemOrder.likes.rawValue

        return item
    }
}
