import ScreenObject
import XCTest

public class StatsScreen: ScreenObject {
    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init {
            $0.otherElements["stats-dashboard"].firstMatch
        }
    }

    @discardableResult
    public func selectByYearPeriod() -> Self {
        app.buttons["Days"].tap()
        app.buttons["Years"].tap()
        return self
    }

    @discardableResult
    public func selectVisitorsTab() -> Self {
        app.buttons["visitors"].tap()
        return self
    }

    @discardableResult
    public func dismissCustomizeInsightsNotice() -> Self {
        let button = app.buttons["dismiss-customize-insights-cell"].firstMatch
        if button.exists {
            button.tap()
        }
        return self
    }

    @discardableResult
    public func switchTo(mode: String) -> Self {
        let button = app.buttons.first(where: {
            $0.identifier.compare(mode, options: [.caseInsensitive]) == .orderedSame ||
            $0.label.compare(mode, options: [.caseInsensitive]) == .orderedSame
        })?.firstMatch
        XCTAssertNotNil(button)
        button?.tap()
        return self
    }

    public func refreshStatsIfNeeded() -> Self {
        let errorMessage = NSPredicate(format: "label == 'An error occurred.'")
        let isErrorMessagePresent = app.staticTexts.element(matching: errorMessage).exists
        let expectedCardsWithoutData = 3
        let isDataLoaded = app.staticTexts.matching(identifier: "No data yet").count <= expectedCardsWithoutData

        if isErrorMessagePresent == true || isDataLoaded == false { pullToRefresh() }

        return self
    }
}
