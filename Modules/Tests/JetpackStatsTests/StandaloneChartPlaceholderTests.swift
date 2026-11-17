import Testing
import Foundation
@testable import JetpackStats

@Suite
@MainActor
struct StandaloneChartPlaceholderTests {
    let calendar = Calendar.mock(timeZone: TimeZone(secondsFromGMT: 0)!)

    @Test
    func weeklyPlaceholderMatchesLoadedDates() {
        let range = StatsDateRange(
            interval: DateInterval(start: Date("2026-08-25T00:00:00Z"), end: Date("2026-11-17T00:00:00Z")),
            component: .day,
            calendar: calendar
        )
        let placeholder = PlaceholderChartDataCache(dateAlignment: .rangeStart)
            .data(metric: .views, granularity: .week, range: range)
        let aggregator = StatsDataAggregator(calendar: calendar)
        let current = aggregator.processPeriod(
            dataPoints: [],
            dateInterval: range.dateInterval,
            granularity: .week,
            metric: SiteMetric.views
        )
        let previous = aggregator.processPeriod(
            dataPoints: [],
            dateInterval: range.effectiveComparisonInterval,
            granularity: .week,
            metric: SiteMetric.views
        )

        #expect(current.dataPoints.count == 12)
        #expect(current.dataPoints.first?.date == Date("2026-08-25T00:00:00Z"))
        #expect(current.dataPoints.last?.date == Date("2026-11-10T00:00:00Z"))
        #expect(placeholder.currentData.map(\.date) == current.dataPoints.map(\.date))
        #expect(placeholder.previousData.map(\.date) == previous.dataPoints.map(\.date))
    }

    @Test
    func monthlyPlaceholderMatchesLoadedDates() {
        let range = StatsDateRange(
            interval: DateInterval(start: Date("2025-01-20T00:00:00Z"), end: Date("2025-02-17T00:00:00Z")),
            component: .day,
            calendar: calendar
        )
        let placeholder = PlaceholderChartDataCache(dateAlignment: .rangeStart)
            .data(metric: .views, granularity: .month, range: range)
        let aggregator = StatsDataAggregator(calendar: calendar)
        let current = aggregator.processPeriod(
            dataPoints: [],
            dateInterval: range.dateInterval,
            granularity: .month,
            metric: SiteMetric.views
        )
        let previous = aggregator.processPeriod(
            dataPoints: [],
            dateInterval: range.effectiveComparisonInterval,
            granularity: .month,
            metric: SiteMetric.views
        )

        #expect(current.dataPoints.map(\.date) == [Date("2025-01-20T00:00:00Z")])
        #expect(placeholder.currentData.map(\.date) == current.dataPoints.map(\.date))
        #expect(placeholder.previousData.map(\.date) == previous.dataPoints.map(\.date))
    }
}
