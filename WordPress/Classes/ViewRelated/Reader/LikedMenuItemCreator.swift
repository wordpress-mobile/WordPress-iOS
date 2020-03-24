import Gridicons

/// Encapsulates creating of a ReaderMenuItem for Liked
final class LikedMenuItemCreator: ReaderMenuItemCreator {
    func supports(_ topic: ReaderAbstractTopic) -> Bool {
        return ReaderHelpers.topicIsLiked(topic)
    }

    func menuItem(with topic: ReaderAbstractTopic) -> ReaderMenuItem {
        var item = ReaderMenuItem(title: topic.title,
                                  type: .topic,
                                  icon: .gridicon(.star),
                                  topic: topic)
        item.order = ReaderDefaultMenuItemOrder.likes.rawValue

        return item
    }
}
