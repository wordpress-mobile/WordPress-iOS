import Foundation
import Testing
import JetpackStatsWidgetsCore

struct ThisWeekWidgetStatsTests {
    @Test func testDaysFromSummaryData_moreSummaryData() {
        var summaryData: [ThisWeekWidgetStats.Input] = []

        // Given there's summary data for more than max days to display
        for _ in 0..<ThisWeekWidgetStats.maxDaysToDisplay + 10 {
            summaryData.append(ThisWeekWidgetStats.Input(periodStartDate: Date(), viewsCount: 1))
        }

        // Then the method should not crash
        // and return maxDaysToDisplay number of days
        let days = ThisWeekWidgetStats.daysFrom(summaryData: summaryData)
        #expect(days.count == ThisWeekWidgetStats.maxDaysToDisplay)
    }

    @Test func testDaysFromSummaryData_lessSummaryData() {
        var summaryData: [ThisWeekWidgetStats.Input] = []

        // Given there's summary data for less than max days to display
        for _ in 0..<ThisWeekWidgetStats.maxDaysToDisplay - 1 {
            summaryData.append(ThisWeekWidgetStats.Input(periodStartDate: Date(), viewsCount: 1))
        }

        // Then the method should not crash
        // and have expected number of This Week data
        let days = ThisWeekWidgetStats.daysFrom(summaryData: summaryData)
        #expect(days.count == ThisWeekWidgetStats.maxDaysToDisplay - 2)
    }
}
