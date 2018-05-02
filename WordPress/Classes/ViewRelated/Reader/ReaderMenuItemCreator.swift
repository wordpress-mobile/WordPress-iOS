protocol ReaderMenuItemCreator {
    func supports(_ topic: ReaderAbstractTopic) -> Bool
    func menuItem(with topic: ReaderAbstractTopic) -> ReaderMenuItem
}
