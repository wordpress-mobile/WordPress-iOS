
/// Encapsulates creating of a ReaderMenuItem for Other
final class OtherMenuItemCreator: ReaderMenuItemCreator {
    func supports(_ topic: ReaderAbstractTopic) -> Bool {
        return true
    }

    func menuItem(with topic: ReaderAbstractTopic) -> ReaderMenuItem {
        var item = ReaderMenuItem(title: topic.title,
                                  type: .topic,
                                  icon: nil,
                                  topic: topic)
        item.order = ReaderDefaultMenuItemOrder.other.rawValue

        return item
    }
}
