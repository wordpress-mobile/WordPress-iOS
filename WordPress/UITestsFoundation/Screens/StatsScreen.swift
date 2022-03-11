import ScreenObject
import XCTest

public class StatsScreen: ScreenObject {

    public enum Mode: String {
        case insights
        case months
        case years
    }

    private enum Timeouts {
        static let short: TimeInterval = 1
        static let `default`: TimeInterval = 3
        static let long: TimeInterval = 10
    }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            // swiftlint:disable:next opening_brace
            expectedElementGetters: [{ $0.otherElements.firstMatch }],
            app: app,
            waitTimeout: 7
        )
    }

    public func verifyStatsLoaded(_ stats: [String]) -> Bool {
        for stat in stats {
            guard app.staticTexts[stat].waitForExistence(timeout: Timeouts.default) else {
                Logger.log(message: "Element not found: \(stat)", event: LogEvent.e)
                return false
            }
        }
        return true
    }

    public func verifyChartLoaded(_ chartElements: [String]) -> Bool {
        for chartElement in chartElements {
            guard app.otherElements[chartElement].waitForExistence(timeout: Timeouts.default) else {
                Logger.log(message: "Element not found: \(chartElement)", event: LogEvent.e)
                return false
            }
        }
        return true
    }

    @discardableResult
    public func assertStatsAreLoaded(_ elements: [String]) -> StatsScreen {
        XCTAssert(verifyStatsLoaded(elements))
        return self
    }

    @discardableResult
    public func assertChartIsLoaded(_ elements: [String]) -> StatsScreen {
        XCTAssert(verifyChartLoaded(elements))
        return self
    }

    @discardableResult
    public func dismissCustomizeInsightsNotice() -> StatsScreen {
        let button = app.buttons["dismiss-customize-insights-cell"]

        if button.exists {
            button.tap()
        }

        return self
    }

    @discardableResult
    public func switchTo(mode: Mode) -> StatsScreen {
        app.buttons[mode.rawValue].tap()
        return self
    }

    public func refreshStatsIfNeeded() -> StatsScreen {
        let errorMessage = NSPredicate(format: "label == 'An error occurred.'")
        let isErrorMessagePresent = app.staticTexts.element(matching: errorMessage).exists
        let expectedCardsWithoutData = 3
        let isDataLoaded = app.staticTexts.matching(identifier: "No data yet").count <= expectedCardsWithoutData

        if isErrorMessagePresent == true || isDataLoaded == false { pullToRefresh() }

        return self
    }
}
