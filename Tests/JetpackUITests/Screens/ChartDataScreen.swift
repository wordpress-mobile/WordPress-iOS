import XCTest

/// The sheet listing the values behind the chart card.
final class ChartDataScreen: ScreenObject {
    private let navigationBarGetter: ElementGetter = {
        $0.navigationBars["Chart Data"]
    }

    private let closeButtonGetter: ElementGetter = {
        $0.navigationBars["Chart Data"].buttons["Close"]
    }

    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [navigationBarGetter, closeButtonGetter], app: app)
    }

    @discardableResult
    func close() throws -> StatsScreen {
        closeButtonGetter(app).tap()
        return try StatsScreen(app: app)
    }
}
