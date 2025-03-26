
/// This protocol is intended to be used as an extraction of a class that takes an internal URL (reader post, plugins, etc...)
/// and presents it with the corresponding native element.
/// This plays good with LinkContentRange, where the url represent an specific post, comment, plugin, etc...
///
protocol ContentRouter {
    func routeTo(_ url: URL)
}
