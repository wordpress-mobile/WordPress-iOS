import ScreenObject
import XCTest

public class StatsScreen: ScreenObject {

    private let dismissCustomizeInsightsButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["dismiss-customize-insights-cell"]
    }

    private let byDayButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["By day"]
    }

    private let visitorsButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["visitors"]
    }

    private let byYearButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["By year"]
    }

    private let statsDashboardGetter: (XCUIApplication) -> XCUIElement = {
        $0.otherElements["stats-dashboard"]
    }

    var dismissCustomizeInsightsButton: XCUIElement { dismissCustomizeInsightsButtonGetter(app) }
    var byDayButton: XCUIElement { byDayButtonGetter(app) }
    var byYearButton: XCUIElement { byYearButtonGetter(app) }
    var visitorsButton: XCUIElement { visitorsButtonGetter(app) }
    var statsDashboard: XCUIElement { statsDashboardGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ statsDashboardGetter ],
            app: app
        )
    }

    public func verifyStatsLoaded(_ stats: [String]) -> Bool {
        for stat in stats {
            guard app.staticTexts[stat].waitForExistence(timeout: 10) else {
                Logger.log(message: "Element not found: \(stat)", event: LogEvent.e)
                return false
            }
        }
        return true
    }

    public func verifyChartLoaded(_ chartElements: [String]) -> Bool {
        for chartElement in chartElements {
            guard app.otherElements[chartElement].waitForExistence(timeout: 10) else {
                Logger.log(message: "Element not found: \(chartElement)", event: LogEvent.e)
                return false
            }
        }
        return true
    }

    @discardableResult
    public func selectByYearPeriod() -> Self {
        byDayButton.tap()
        byYearButton.tap()
        return self
    }

    @discardableResult
    public func selectVisitorsTab() -> Self {
        visitorsButton.tap()
        return self
    }

    @discardableResult
    public func assertStatsAreLoaded(_ elements: [String]) -> Self {
        XCTAssert(verifyStatsLoaded(elements))
        return self
    }

    @discardableResult
    public func assertChartIsLoaded(_ elements: [String]) -> Self {
        XCTAssert(verifyChartLoaded(elements))
        return self
    }

    @discardableResult
    public func dismissCustomizeInsightsNotice() -> Self {
        if dismissCustomizeInsightsButton.exists {
            dismissCustomizeInsightsButton.tap()
        }

        return self
    }

    @discardableResult
    public func switchTo(mode: String) -> Self {
        app.buttons[mode].tap()
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
