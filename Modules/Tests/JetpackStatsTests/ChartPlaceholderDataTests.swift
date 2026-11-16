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

    @Test(arguments: [0, 9, 23])
    func todayPlaceholderEndsAtCurrentHour(currentHour: Int) {
        let data = TodayCardData.placeholder(currentHour: currentHour)

        #expect(data.hourlyViews.map(\.hour) == Array(0...currentHour))
        #expect(data.previousHourlyViews?.map(\.hour) == Array(0..<24))
    }
}
