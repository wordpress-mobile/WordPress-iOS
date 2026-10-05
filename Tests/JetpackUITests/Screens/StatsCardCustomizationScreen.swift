import XCTest

/// The sheet for customizing a Traffic tab card: a chart card's metrics, or a top list card's
/// data type.
final class StatsCardCustomizationScreen: ScreenObject {
    private let title: String

    init(title: String, app: XCUIApplication) throws {
        self.title = title
        try super.init(expectedElementGetters: [{ $0.navigationBars[title] }], app: app)
    }

    @discardableResult
    func cancel() throws -> StatsScreen {
        app.navigationBars[title].buttons["Cancel"].tap()
        return try StatsScreen(app: app)
    }
}
