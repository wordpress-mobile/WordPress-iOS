import Testing
import Foundation
@testable import JetpackStats

@Suite
struct ChartPlaceholderDataTests {
    let calendar = Calendar.mock(timeZone: TimeZone(secondsFromGMT: 0)!)

    private func makeMonthRange() -> StatsDateRange {
        StatsDateRange(
            interval: DateInterval(
                start: Date("2025-01-01T00:00:00Z"),
                end: Date("2025-02-01T00:00:00Z")
            ),
            component: .month,
            calendar: calendar
        )
    }

    @Test
    func mockCurrentPeriodStopsAtNow() {
        let data = ChartData.mock(
            metric: .views,
            granularity: .day,
            range: makeMonthRange(),
            now: Date("2025-01-10T12:00:00Z")
        )

        // Jan 1 through Jan 10, like a loaded chart with no future points.
        #expect(data.currentData.count == 10)
        #expect(data.currentData.last?.date == Date("2025-01-10T00:00:00Z"))
        // The previous period covers the whole month.
        #expect(data.mappedPreviousData.count == 31)
    }

    @Test
    func mockCoversPastRangeFully() {
        let data = ChartData.mock(
            metric: .views,
            granularity: .day,
            range: makeMonthRange(),
            now: Date("2025-03-01T00:00:00Z")
        )

        #expect(data.currentData.count == 31)
        #expect(data.mappedPreviousData.count == 31)
    }

    @Test
    func weeksStartOnMondayBeforeTheRangeStart() {
        // Tue 2026-08-25 ..< Tue 2026-11-17 ("Last 12 weeks"), now Mon 2026-11-16.
        let range = StatsDateRange(
            interval: DateInterval(start: Date("2026-08-25T00:00:00Z"), end: Date("2026-11-17T00:00:00Z")),
            component: .weekOfYear,
            calendar: calendar
        )
        let data = ChartData.mock(metric: .views, granularity: .week, range: range, now: Date("2026-11-16T12:00:00Z"))

        // 13 Monday-start weeks, from Mon 24 Aug (before the range start) to Mon 16 Nov.
        #expect(data.currentData.count == 13)
        #expect(data.currentData.first?.date == Date("2026-08-24T00:00:00Z"))
        #expect(data.currentData.last?.date == Date("2026-11-16T00:00:00Z"))
    }

    @Test
    func monthsCoverEveryMonthTheRangeTouches() {
        // 2026-10-20 ..< 2026-11-17 ("Last 28 days") by month.
        let range = StatsDateRange(
            interval: DateInterval(start: Date("2026-10-20T00:00:00Z"), end: Date("2026-11-17T00:00:00Z")),
            component: .day,
            calendar: calendar
        )
        let data = ChartData.mock(metric: .views, granularity: .month, range: range, now: Date("2026-11-16T12:00:00Z"))

        #expect(data.currentData.map(\.date) == [Date("2026-10-01T00:00:00Z"), Date("2026-11-01T00:00:00Z")])
    }

    @Test
    func comparisonIsMappedLikeLoadedData() {
        let range = makeMonthRange()
        let data = ChartData.mock(metric: .views, granularity: .day, range: range, now: Date("2025-03-01T00:00:00Z"))

        let expected = DataPoint.mapDataPoints(
            currentData: data.currentData,
            previousData: data.previousData,
            dateRange: range
        )
        #expect(data.mappedPreviousData.map(\.date) == expected.map(\.date))
    }

    @Test
    func mockUsesRequestedMetric() {
        let data = ChartData.mock(metric: .likes, granularity: .day, range: makeMonthRange())

        #expect(data.metric == .likes)
    }

    @Test
    @MainActor
    func cacheReusesDataUntilInputsChange() {
        let cache = PlaceholderChartDataCache()
        let range = makeMonthRange()

        let first = cache.data(metric: .views, granularity: .day, range: range)
        #expect(cache.data(metric: .views, granularity: .day, range: range) === first)
        #expect(cache.data(metric: .visitors, granularity: .day, range: range) !== first)
        #expect(cache.data(metric: .visitors, granularity: .week, range: range).granularity == .week)
    }

    @Test
    @MainActor
    func comparisonChangeInvalidatesCache() {
        var range = StatsDateRange(
            interval: DateInterval(start: Date("2024-03-01T00:00:00Z"), end: Date("2024-04-01T00:00:00Z")),
            component: .month,
            calendar: calendar
        )
        let cache = PlaceholderChartDataCache()
        let first = cache.data(metric: .views, granularity: .day, range: range)
        #expect(first.mappedPreviousData.count == 29)

        range.update(comparisonPeriod: .samePeriodLastYear)
        let updated = cache.data(metric: .views, granularity: .day, range: range)
        let fresh = ChartData.mock(metric: .views, granularity: .day, range: range)

        #expect(updated !== first)
        #expect(updated.mappedPreviousData.count == 31)
        #expect(updated.mappedPreviousData.map(\.date) == fresh.mappedPreviousData.map(\.date))
        #expect(cache.data(metric: .views, granularity: .day, range: range) === updated)
    }

    @Test
    @MainActor
    func calendarChangeInvalidatesCache() {
        let range = makeMonthRange()
        var otherCalendar = calendar
        otherCalendar.timeZone = TimeZone(secondsFromGMT: -8 * 3600)!
        let otherRange = StatsDateRange(interval: range.dateInterval, component: .month, calendar: otherCalendar)
        let cache = PlaceholderChartDataCache()
        let first = cache.data(metric: .views, granularity: .day, range: range)

        let updated = cache.data(metric: .views, granularity: .day, range: otherRange)
        let fresh = ChartData.mock(metric: .views, granularity: .day, range: otherRange)

        #expect(updated !== first)
        #expect(updated.currentData.map(\.date) == fresh.currentData.map(\.date))
        #expect(updated.previousData.map(\.date) == fresh.previousData.map(\.date))
        #expect(cache.data(metric: .views, granularity: .day, range: otherRange) === updated)
    }

    @Test(arguments: [0, 9, 23])
    func todayPlaceholderEndsAtCurrentHour(currentHour: Int) {
        let data = TodayCardData.placeholder(currentHour: currentHour)

        #expect(data.hourlyViews.map(\.hour) == Array(0...currentHour))
        #expect(data.previousHourlyViews?.map(\.hour) == Array(0..<24))
    }
}
