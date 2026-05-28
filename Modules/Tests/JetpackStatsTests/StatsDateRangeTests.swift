import Testing
import Foundation
@testable import JetpackStats

@Suite
struct StatsDateRangeTests {
    let calendar = Calendar.mock(timeZone: TimeZone(secondsFromGMT: 0)!)

    @Test
    func testNavigateToPrevious() {
        // GIVEN
        let initialRange = StatsDateRange(
            interval: DateInterval(
                start: Date("2025-01-15T00:00:00Z"),
                end: Date("2025-01-16T00:00:00Z")
            ),
            component: .day,
            calendar: calendar
        )

        // WHEN
        let previousRange = initialRange.navigate(.backward)

        // THEN
        #expect(previousRange.dateInterval.start == Date("2025-01-14T00:00:00Z"))
        #expect(previousRange.dateInterval.end == Date("2025-01-15T00:00:00Z"))
        #expect(previousRange.calendar == calendar)
        #expect(previousRange.component == .day)
    }

    @Test
    func testNavigateToNext() {
        // GIVEN
        let initialRange = StatsDateRange(
            interval: DateInterval(
                start: Date("2025-01-15T00:00:00Z"),
                end: Date("2025-01-16T00:00:00Z")
            ),
            component: .day,
            calendar: calendar
        )

        // WHEN
        let nextRange = initialRange.navigate(.forward)

        // THEN
        #expect(nextRange.dateInterval.start == Date("2025-01-16T00:00:00Z"))
        #expect(nextRange.dateInterval.end == Date("2025-01-17T00:00:00Z"))
        #expect(nextRange.calendar == calendar)
        #expect(nextRange.component == .day)
    }

    @Test
    func testCalendarIsPreservedInNavigation() {
        // GIVEN
        var customCalendar = Calendar(identifier: .gregorian)
        customCalendar.timeZone = TimeZone(identifier: "America/New_York")!

        let initialRange = StatsDateRange(
            interval: DateInterval(
                start: Date("2025-01-15T00:00:00Z"),
                end: Date("2025-01-16T00:00:00Z")
            ),
            component: .day,
            calendar: customCalendar
        )

        // WHEN
        let nextRange = initialRange.navigate(.forward)

        // THEN
        #expect(nextRange.calendar.timeZone == customCalendar.timeZone)
    }

    @Test
    func testAvailableAdjacentPeriods() {
        // GIVEN
        let now = Date("2025-12-31T23:59:59Z") // Fixed date in 2025 for consistent test results
        let initialRange = StatsDateRange(
            interval: DateInterval(
                start: Date("2020-01-01T00:00:00Z"),
                end: Date("2021-01-01T00:00:00Z")
            ),
            component: .year,
            calendar: calendar
        )

        // WHEN - Test backward navigation
        let backwardPeriods = initialRange.availableAdjacentPeriods(in: .backward, maxCount: 10, now: now)

        // THEN
        #expect(backwardPeriods.count == 10)
        #expect(backwardPeriods[0].displayText == "2019")
        #expect(backwardPeriods[1].displayText == "2018")
        #expect(backwardPeriods[2].displayText == "2017")
        #expect(backwardPeriods[9].displayText == "2010")

        // Verify ranges are correct
        #expect(backwardPeriods[0].range.dateInterval.start == Date("2019-01-01T00:00:00Z"))
        #expect(backwardPeriods[0].range.dateInterval.end == Date("2020-01-01T00:00:00Z"))

        // WHEN - Test forward navigation (should be limited by current date)
        let forwardPeriods = initialRange.availableAdjacentPeriods(in: .forward, maxCount: 10, now: now)

        // THEN - Should have 5 periods available (2021, 2022, 2023, 2024, 2025)
        #expect(forwardPeriods.count == 5)
        #expect(forwardPeriods[0].displayText == "2021")
        #expect(forwardPeriods[1].displayText == "2022")
        #expect(forwardPeriods[4].displayText == "2025")

        // Verify all periods have unique IDs
        let ids = backwardPeriods.map(\.id) + forwardPeriods.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    // MARK: - X-Axis Domain Tests

    @Test
    func testXAxisDomainWithDataWithinRequestedPeriod() {
        // GIVEN - "This week" with daily granularity, all data points within the week
        let weekStart = Date("2026-01-27T00:00:00Z")
        let weekEnd = Date("2026-02-03T00:00:00Z")
        let dateInterval = DateInterval(start: weekStart, end: weekEnd)

        let dataPoints = [
            DataPoint(date: Date("2026-01-27T00:00:00Z"), value: 100),
            DataPoint(date: Date("2026-01-28T00:00:00Z"), value: 150),
            DataPoint(date: Date("2026-01-29T00:00:00Z"), value: 200)
        ]

        // WHEN
        let domain = ChartHelper.xAxisDomain(
            for: dateInterval,
            dataPoints: dataPoints,
            granularity: .day,
            calendar: calendar
        )

        // THEN - Standard case: use requested interval as-is
        #expect(domain.lowerBound == weekStart)
        #expect(domain.upperBound == weekEnd)
    }

    @Test
    func testXAxisDomainWithYearGranularityForWeekPeriod() {
        // GIVEN - "This week" with year granularity (edge case!)
        // The year data point falls on Jan 1, which is before the week starts on Jan 27
        let weekStart = Date("2026-01-27T00:00:00Z")
        let weekEnd = Date("2026-02-03T00:00:00Z")
        let dateInterval = DateInterval(start: weekStart, end: weekEnd)

        let dataPoints = [
            DataPoint(date: Date("2026-01-01T00:00:00Z"), value: 5000) // Year data point
        ]

        // WHEN
        let domain = ChartHelper.xAxisDomain(
            for: dateInterval,
            dataPoints: dataPoints,
            granularity: .year,
            calendar: calendar
        )

        // THEN - Domain extended to include the entire year containing the data point
        #expect(domain.lowerBound == Date("2026-01-01T00:00:00Z")) // Start of 2026
        #expect(domain.upperBound == Date("2027-01-01T00:00:00Z"))  // Start of 2027
    }

    @Test
    func testXAxisDomainWithMonthGranularityForWeekPeriod() {
        // GIVEN - "This week" with month granularity
        let weekStart = Date("2026-01-27T00:00:00Z")
        let weekEnd = Date("2026-02-03T00:00:00Z")
        let dateInterval = DateInterval(start: weekStart, end: weekEnd)

        let dataPoints = [
            DataPoint(date: Date("2026-02-01T00:00:00Z"), value: 1000) // Month data point
        ]

        // WHEN
        let domain = ChartHelper.xAxisDomain(
            for: dateInterval,
            dataPoints: dataPoints,
            granularity: .month,
            calendar: calendar
        )

        // THEN - Data point within interval, domain unchanged
        #expect(domain.lowerBound == Date("2026-01-27T00:00:00Z"))
        #expect(domain.upperBound == Date("2026-02-03T00:00:00Z"))
    }

    @Test
    func testXAxisDomainWithEmptyDataPoints() {
        // GIVEN - No data points
        let weekStart = Date("2026-01-27T00:00:00Z")
        let weekEnd = Date("2026-02-03T00:00:00Z")
        let dateInterval = DateInterval(start: weekStart, end: weekEnd)

        let dataPoints: [DataPoint] = []

        // WHEN
        let domain = ChartHelper.xAxisDomain(
            for: dateInterval,
            dataPoints: dataPoints,
            granularity: .day,
            calendar: calendar
        )

        // THEN - With no data, use the requested interval as-is
        #expect(domain.lowerBound == weekStart)
        #expect(domain.upperBound == weekEnd)
    }

    @Test
    func testXAxisDomainWithSingleDataPoint() {
        // GIVEN - Single data point
        let monthStart = Date("2026-01-01T00:00:00Z")
        let monthEnd = Date("2026-02-01T00:00:00Z")
        let dateInterval = DateInterval(start: monthStart, end: monthEnd)

        let dataPoints = [
            DataPoint(date: Date("2026-01-15T00:00:00Z"), value: 100)
        ]

        // WHEN
        let domain = ChartHelper.xAxisDomain(
            for: dateInterval,
            dataPoints: dataPoints,
            granularity: .day,
            calendar: calendar
        )

        // THEN - Standard case: use requested interval as-is
        #expect(domain.lowerBound == monthStart)
        #expect(domain.upperBound == monthEnd)
    }

    @Test
    func testXAxisDomainWithSparseData() {
        // GIVEN - Sparse data with gaps
        let monthStart = Date("2026-01-01T00:00:00Z")
        let monthEnd = Date("2026-02-01T00:00:00Z")
        let dateInterval = DateInterval(start: monthStart, end: monthEnd)

        let dataPoints = [
            DataPoint(date: Date("2026-01-01T00:00:00Z"), value: 100),
            DataPoint(date: Date("2026-01-15T00:00:00Z"), value: 150),
            DataPoint(date: Date("2026-01-31T00:00:00Z"), value: 200)
        ]

        // WHEN
        let domain = ChartHelper.xAxisDomain(
            for: dateInterval,
            dataPoints: dataPoints,
            granularity: .day,
            calendar: calendar
        )

        // THEN - Standard case: use requested interval as-is
        #expect(domain.lowerBound == monthStart)
        #expect(domain.upperBound == monthEnd)
    }

    @Test
    func testXAxisDomainWithDataPointsExtendingBeyondRequestedPeriod() {
        // GIVEN - Data points that extend beyond the requested interval on both ends
        let weekStart = Date("2026-01-13T00:00:00Z")
        let weekEnd = Date("2026-01-20T00:00:00Z")
        let dateInterval = DateInterval(start: weekStart, end: weekEnd)

        let dataPoints = [
            DataPoint(date: Date("2026-01-10T00:00:00Z"), value: 100), // Before range
            DataPoint(date: Date("2026-01-15T00:00:00Z"), value: 150), // Within range
            DataPoint(date: Date("2026-01-25T00:00:00Z"), value: 200)  // After range
        ]

        // WHEN
        let domain = ChartHelper.xAxisDomain(
            for: dateInterval,
            dataPoints: dataPoints,
            granularity: .day,
            calendar: calendar
        )

        // THEN - Domain extended to include all data points, aligned to day boundaries
        #expect(domain.lowerBound == Date("2026-01-10T00:00:00Z")) // Start of Jan 10
        #expect(domain.upperBound == Date("2026-01-26T00:00:00Z"))  // Start of Jan 26 (day after Jan 25)
    }
}
