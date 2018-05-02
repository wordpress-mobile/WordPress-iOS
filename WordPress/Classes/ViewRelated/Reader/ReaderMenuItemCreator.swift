/// Interface abstracting the entities that create menu items for the different topics presented in Reader
protocol ReaderMenuItemCreator {
    func supports(_ topic: ReaderAbstractTopic) -> Bool
    func menuItem(with topic: ReaderAbstractTopic) -> ReaderMenuItem
}
