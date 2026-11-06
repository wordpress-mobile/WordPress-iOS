import XCTest

/// The sheet for picking the stats' date range by its start and end dates.
final class CustomDateRangeScreen: ScreenObject {
    private let navigationBarGetter: ElementGetter = {
        $0.navigationBars["Select Range"]
    }

    private let cancelButtonGetter: ElementGetter = {
        $0.navigationBars["Select Range"].buttons["Cancel"]
    }

    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [navigationBarGetter, cancelButtonGetter], app: app)
    }

    @discardableResult
    func cancel() throws -> StatsScreen {
        cancelButtonGetter(app).tap()
        return try StatsScreen(app: app)
    }
}
