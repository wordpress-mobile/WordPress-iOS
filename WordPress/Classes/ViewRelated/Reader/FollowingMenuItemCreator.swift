import Gridicons

/// Encapsulates creating of a ReaderMenuItem for Following
final class FollowingMenuItemCreator: ReaderMenuItemCreator {
    func supports(_ topic: ReaderAbstractTopic) -> Bool {
        return ReaderHelpers.topicIsFollowing(topic)
    }

    func menuItem(with topic: ReaderAbstractTopic) -> ReaderMenuItem {
        var item = ReaderMenuItem(title: topic.title,
                                  type: .topic,
                                  icon: .gridicon(.checkmarkCircle),
                                  topic: topic)
        item.order = ReaderDefaultMenuItemOrder.followed.rawValue

        return item
    }
}
