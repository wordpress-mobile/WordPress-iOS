import XCTest
import JetpackStatsWidgetsCore

final class ThisWeekWidgetStatsTests: XCTestCase {
    func testDaysFromSummaryData_moreSummaryData() {
        var summaryData: [ThisWeekWidgetStats.Input] = []

        // Given there's summary data for more than max days to display
        for _ in 0..<ThisWeekWidgetStats.maxDaysToDisplay + 10 {
            summaryData.append(ThisWeekWidgetStats.Input(periodStartDate: Date(), viewsCount: 1))
        }

        // Then the method should not crash
        // and return maxDaysToDisplay number of days
        let days = ThisWeekWidgetStats.daysFrom(summaryData: summaryData)
        XCTAssertEqual(days.count, ThisWeekWidgetStats.maxDaysToDisplay)
    }

    func testDaysFromSummaryData_lessSummaryData() {
        var summaryData: [ThisWeekWidgetStats.Input] = []

        // Given there's summary data for less than max days to display
        for _ in 0..<ThisWeekWidgetStats.maxDaysToDisplay - 1 {
            summaryData.append(ThisWeekWidgetStats.Input(periodStartDate: Date(), viewsCount: 1))
        }

        // Then the method should not crash
        // and have expected number of This Week data
        let days = ThisWeekWidgetStats.daysFrom(summaryData: summaryData)
        XCTAssertEqual(days.count, ThisWeekWidgetStats.maxDaysToDisplay - 2)
    }
}
