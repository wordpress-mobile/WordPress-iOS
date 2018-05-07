import Gridicons

/// Encapsulates creating of a ReaderMenuItem for Bookmarks / Saved for Later
final class SavedForLaterMenuItemCreator: ReaderMenuItemCreator {
    func supports(_ topic: ReaderAbstractTopic) -> Bool {
        return ReaderHelpers.topicIsSavedForLater(topic)
    }

    func menuItem(with topic: ReaderAbstractTopic) -> ReaderMenuItem {
        var item = ReaderMenuItem(title: topic.title,
                                  type: .topic,
                                  icon: Gridicon.iconOfType(.bookmark),
                                  topic: topic)
        item.order = ReaderDefaultMenuItemOrder.savedForLater.rawValue

        return item
    }
}
