import Testing
import Foundation
@testable import JetpackStats

@Suite
struct DateRangeComparisonPeriodTests {
    let calendar = Calendar.mock(timeZone: TimeZone(secondsFromGMT: 0)!)

    // MARK: - DateRangeComparisonPeriod Tests

    @Test
    func testPrecedingPeriodForDay() {
        // GIVEN
        let currentRange = DateInterval(
            start: Date("2025-01-15T00:00:00Z"),
            end: Date("2025-01-16T00:00:00Z")
        )

        // WHEN
        let comparisonRange = calendar.comparisonRange(for: currentRange, period: .precedingPeriod, component: .day)

        // THEN
        #expect(comparisonRange.start == Date("2025-01-14T00:00:00Z"))
        #expect(comparisonRange.end == Date("2025-01-15T00:00:00Z"))
    }

    @Test
    func testPrecedingPeriodForWeek() {
        // GIVEN
        let currentRange = DateInterval(
            start: Date("2025-01-12T00:00:00Z"), // Sunday
            end: Date("2025-01-19T00:00:00Z")    // Next Sunday
        )

        // WHEN
        let comparisonRange = calendar.comparisonRange(for: currentRange, period: .precedingPeriod, component: .weekOfYear)

        // THEN
        #expect(comparisonRange.start == Date("2025-01-05T00:00:00Z"))
        #expect(comparisonRange.end == Date("2025-01-12T00:00:00Z"))
    }

    @Test
    func testPrecedingPeriodForMonth() {
        // GIVEN
        let currentRange = DateInterval(
            start: Date("2025-02-01T00:00:00Z"),
            end: Date("2025-03-01T00:00:00Z")
        )

        // WHEN
        let comparisonRange = calendar.comparisonRange(for: currentRange, period: .precedingPeriod, component: .month)

        // THEN
        #expect(comparisonRange.start == Date("2025-01-01T00:00:00Z"))
        #expect(comparisonRange.end == Date("2025-02-01T00:00:00Z"))
    }

    @Test
    func testPrecedingPeriodForYear() {
        // GIVEN
        let currentRange = DateInterval(
            start: Date("2025-01-01T00:00:00Z"),
            end: Date("2026-01-01T00:00:00Z")
        )

        // WHEN
        let comparisonRange = calendar.comparisonRange(for: currentRange, period: .precedingPeriod, component: .year)

        // THEN
        #expect(comparisonRange.start == Date("2024-01-01T00:00:00Z"))
        #expect(comparisonRange.end == Date("2025-01-01T00:00:00Z"))
    }

    @Test
    func testPrecedingPeriodForCustomRange() {
        // GIVEN - 7 day custom range
        let currentRange = DateInterval(
            start: Date("2025-01-08T00:00:00Z"),
            end: Date("2025-01-15T00:00:00Z")
        )

        // WHEN - Use nil component for custom ranges
        let comparisonRange = calendar.comparisonRange(for: currentRange, period: .precedingPeriod, component: .day)

        // THEN - Should shift by duration (7 days)
        #expect(comparisonRange.start == Date("2025-01-01T00:00:00Z"))
        #expect(comparisonRange.end == Date("2025-01-08T00:00:00Z"))
    }

    @Test
    func testSamePeriodLastYearForDay() {
        // GIVEN
        let currentRange = DateInterval(
            start: Date("2025-01-15T00:00:00Z"),
            end: Date("2025-01-16T00:00:00Z")
        )

        // WHEN
        let comparisonRange = calendar.comparisonRange(for: currentRange, period: .samePeriodLastYear, component: .day)

        // THEN
        #expect(comparisonRange.start == Date("2024-01-15T00:00:00Z"))
        #expect(comparisonRange.end == Date("2024-01-16T00:00:00Z"))
    }

    @Test
    func testSamePeriodLastYearForMonth() {
        // GIVEN
        let currentRange = DateInterval(
            start: Date("2025-02-01T00:00:00Z"),
            end: Date("2025-03-01T00:00:00Z")
        )

        // WHEN
        let comparisonRange = calendar.comparisonRange(for: currentRange, period: .samePeriodLastYear, component: .month)

        // THEN
        #expect(comparisonRange.start == Date("2024-02-01T00:00:00Z"))
        #expect(comparisonRange.end == Date("2024-03-01T00:00:00Z"))
    }

    @Test
    func testSamePeriodLastYearForLeapYear() {
        // GIVEN - February 29, 2024 (leap year)
        let currentRange = DateInterval(
            start: Date("2024-02-29T00:00:00Z"),
            end: Date("2024-03-01T00:00:00Z")
        )

        // WHEN
        let comparisonRange = calendar.comparisonRange(for: currentRange, period: .samePeriodLastYear, component: .day)

        // THEN - Should handle leap year correctly
        #expect(comparisonRange.start == Date("2023-02-28T00:00:00Z"))
        #expect(comparisonRange.end == Date("2023-03-01T00:00:00Z"))
    }

    // MARK: - StatsDateRange Integration Tests

    @Test
    func testStatsDateRangeWithComparisonType() {
        // GIVEN
        let currentRange = DateInterval(
            start: Date("2025-01-15T00:00:00Z"),
            end: Date("2025-01-16T00:00:00Z")
        )

        // WHEN
        let dateRange = StatsDateRange(
            interval: currentRange,
            component: .day,
            comparison: .precedingPeriod,
            calendar: calendar
        )

        // THEN
        #expect(dateRange.comparison == DateRangeComparisonPeriod.precedingPeriod)
        #expect(dateRange.effectiveComparisonInterval.start == Date("2025-01-14T00:00:00Z"))
        #expect(dateRange.effectiveComparisonInterval.end == Date("2025-01-15T00:00:00Z"))
    }

    @Test
    func testNavigationPreservesComparisonType() {
        // GIVEN
        let initialRange = StatsDateRange(
            interval: DateInterval(
                start: Date("2025-01-15T00:00:00Z"),
                end: Date("2025-01-16T00:00:00Z")
            ),
            component: .day,
            comparison: .samePeriodLastYear,
            calendar: calendar
        )

        // WHEN
        let nextRange = initialRange.navigate(.forward)

        // THEN - Comparison type should be preserved
        #expect(nextRange.comparison == .samePeriodLastYear)
        #expect(nextRange.dateInterval.start == Date("2025-01-16T00:00:00Z"))
        #expect(nextRange.effectiveComparisonInterval.start == Date("2024-01-16T00:00:00Z"))
    }
}
