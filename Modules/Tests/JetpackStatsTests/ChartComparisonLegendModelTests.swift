import Foundation
import Testing
@testable import JetpackStats

@Suite
struct ChartComparisonLegendModelTests {
    private let calendar = Calendar.mock(timeZone: .eastern)
    private let formatter = StatsDateRangeFormatter(
        locale: Locale(identifier: "en_US"),
        timeZone: .eastern,
        now: { Date("2026-08-17T12:00:00-03:00") }
    )

    @Test("Preceding-period legend uses concrete intervals for a preset")
    func precedingPeriodUsesConcreteIntervals() {
        let dateRange = StatsDateRange(
            interval: DateInterval(
                start: Date("2026-08-08T00:00:00-03:00"),
                end: Date("2026-08-15T00:00:00-03:00")
            ),
            component: .day,
            comparison: .precedingPeriod,
            calendar: calendar,
            preset: .last7Days
        )

        let model = ChartComparisonLegendModel(
            dateRange: dateRange,
            chartType: .line,
            formatter: formatter
        )

        #expect(model.currentPeriod == "Aug 8 – 14")
        #expect(model.comparisonPeriod == "Preceding Period · Aug 1 – 7")
        #expect(model.style == .lines)
    }

    @Test("Last-year legend names the comparison and includes its year")
    func lastYearIncludesComparisonYear() {
        let dateRange = StatsDateRange(
            interval: DateInterval(
                start: Date("2026-08-08T00:00:00-03:00"),
                end: Date("2026-08-15T00:00:00-03:00")
            ),
            component: .day,
            comparison: .samePeriodLastYear,
            calendar: calendar
        )

        let model = ChartComparisonLegendModel(
            dateRange: dateRange,
            chartType: .columns,
            formatter: formatter
        )

        #expect(model.currentPeriod == "Aug 8 – 14")
        #expect(model.comparisonPeriod == "Last Year · Aug 8 – 14, 2025")
        #expect(model.style == .bars)
    }

    @Test("Custom cross-year legend formats both concrete intervals")
    func customCrossYearRange() {
        let dateRange = StatsDateRange(
            interval: DateInterval(
                start: Date("2025-12-28T00:00:00-03:00"),
                end: Date("2026-01-04T00:00:00-03:00")
            ),
            component: .day,
            comparison: .precedingPeriod,
            calendar: calendar
        )

        let model = ChartComparisonLegendModel(
            dateRange: dateRange,
            chartType: .line,
            formatter: formatter
        )

        #expect(model.currentPeriod == "Dec 28, 2025 – Jan 3, 2026")
        #expect(model.comparisonPeriod == "Preceding Period · Dec 21 – 27, 2025")
    }
}
