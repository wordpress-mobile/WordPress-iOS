import XCTest

/// A screen pushed from a stats card, identified by its title: a top list's full list, the stats
/// for one of its items, or the details of an insight.
final class StatsDetailsScreen: ScreenObject {
    init(title: String, app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [Self.navigationBarTitle(title)], app: app)
    }
}
