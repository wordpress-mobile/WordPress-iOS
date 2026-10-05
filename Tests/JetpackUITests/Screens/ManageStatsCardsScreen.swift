import XCTest

/// The sheet for choosing which cards the Insights tab shows.
final class ManageStatsCardsScreen: ScreenObject {
    private let navigationBarGetter: ElementGetter = {
        $0.navigationBars["Manage Stats Cards"]
    }

    private let closeButtonGetter: ElementGetter = {
        $0.navigationBars["Manage Stats Cards"].buttons.firstMatch
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
