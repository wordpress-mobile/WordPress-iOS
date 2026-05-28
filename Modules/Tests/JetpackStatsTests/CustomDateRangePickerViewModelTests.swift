import Testing
import Foundation
@testable import JetpackStats

@Suite @MainActor
struct CustomDateRangePickerViewModelTests {
    let calendar = Calendar.mock(timeZone: .eastern)

    // MARK: - Initialization Tests

    @Test("Initialize with single-day range")
    func initializeSingleDay() {
        // GIVEN - A date range representing Feb 3, 2026 (inclusive)
        let interval = DateInterval(
            start: Date("2026-02-03T00:00:00-03:00"),
            end: Date("2026-02-04T00:00:00-03:00")  // End is exclusive, so this represents Feb 3
        )
        let dateRange = StatsDateRange(interval: interval, component: .day, comparison: .off, calendar: calendar)

        // WHEN
        let viewModel = CustomDateRangePickerViewModel(dateRange: dateRange, calendar: calendar)

        // THEN - Start should be Feb 3, end should be Feb 3 minus 1 second (for display)
        #expect(viewModel.startDate == Date("2026-02-03T00:00:00-03:00"))
        #expect(viewModel.endDate.timeIntervalSince(Date("2026-02-03T23:59:59-03:00")) < 1)

        // Formatted count should show "1 day" for a single day
        #expect(viewModel.formattedDateCount == "1 day")
    }

    @Test("Initialize with multi-day range")
    func initializeMultiDay() {
        // GIVEN - A date range from Feb 1 to Feb 5 (inclusive)
        let interval = DateInterval(
            start: Date("2026-02-01T00:00:00-03:00"),
            end: Date("2026-02-06T00:00:00-03:00")
        )
        let dateRange = StatsDateRange(interval: interval, component: .day, comparison: .off, calendar: calendar)

        // WHEN
        let viewModel = CustomDateRangePickerViewModel(dateRange: dateRange, calendar: calendar)

        // THEN
        #expect(viewModel.startDate == Date("2026-02-01T00:00:00-03:00"))
        #expect(viewModel.endDate.timeIntervalSince(Date("2026-02-05T23:59:59-03:00")) < 1)

        // Formatted count should show "5 days"
        #expect(viewModel.formattedDateCount == "5 days")
    }

    // MARK: - Formatted Date Count Tests

    @Test("Single day shows '1 day'")
    func singleDayCount() {
        // GIVEN - Feb 3 to Feb 3 (same day)
        let interval = DateInterval(
            start: Date("2026-02-03T00:00:00-03:00"),
            end: Date("2026-02-04T00:00:00-03:00")
        )
        let dateRange = StatsDateRange(interval: interval, component: .day, comparison: .off, calendar: calendar)
        let viewModel = CustomDateRangePickerViewModel(dateRange: dateRange, calendar: calendar)

        // WHEN
        let formatted = viewModel.formattedDateCount

        // THEN - Should show "1 day" not "0 days"
        #expect(formatted == "1 day")
    }

    @Test("Multiple days show correct count", arguments: [
        (Date("2026-02-01T00:00:00-03:00"), Date("2026-02-03T00:00:00-03:00"), "2 days"),  // Feb 1-2
        (Date("2026-02-01T00:00:00-03:00"), Date("2026-02-08T00:00:00-03:00"), "7 days"),  // Week
        (Date("2026-02-01T00:00:00-03:00"), Date("2026-02-16T00:00:00-03:00"), "15 days"), // Two weeks
        (Date("2026-01-01T00:00:00-03:00"), Date("2026-02-01T00:00:00-03:00"), "31 days")  // Full month
    ])
    func multipleDaysCount(startDate: Date, endDate: Date, expected: String) {
        // GIVEN
        let interval = DateInterval(start: startDate, end: endDate)
        let dateRange = StatsDateRange(interval: interval, component: .day, comparison: .off, calendar: calendar)
        let viewModel = CustomDateRangePickerViewModel(dateRange: dateRange, calendar: calendar)

        // WHEN
        let formatted = viewModel.formattedDateCount

        // THEN
        #expect(formatted == expected)
    }

    // MARK: - Date Adjustment Tests

    @Test("Adjusting start date after end date moves end date forward")
    func adjustEndDateAfterStartDate() {
        // GIVEN - Initially Feb 1 to Feb 5
        let interval = DateInterval(
            start: Date("2026-02-01T00:00:00-03:00"),
            end: Date("2026-02-06T00:00:00-03:00")
        )
        let dateRange = StatsDateRange(interval: interval, component: .day, comparison: .off, calendar: calendar)
        let viewModel = CustomDateRangePickerViewModel(dateRange: dateRange, calendar: calendar)

        // Initial count should be 5 days
        #expect(viewModel.formattedDateCount == "5 days")

        // WHEN - Move start date to Feb 10 (after current end date)
        // ViewModel should automatically adjust end date
        viewModel.startDate = Date("2026-02-10T00:00:00-03:00")

        // THEN - End date should be automatically adjusted to Feb 11
        let expectedEnd = calendar.startOfDay(for: Date("2026-02-11T00:00:00-03:00"))
        let actualEnd = calendar.startOfDay(for: viewModel.endDate)
        #expect(actualEnd == expectedEnd)

        // Count should now be 2 days (Feb 10-11)
        #expect(viewModel.formattedDateCount == "2 days")
    }

    @Test("Adjusting end date before start date moves start date backward")
    func adjustStartDateBeforeEndDate() {
        // GIVEN - Initially Feb 5 to Feb 10
        let interval = DateInterval(
            start: Date("2026-02-05T00:00:00-03:00"),
            end: Date("2026-02-11T00:00:00-03:00")
        )
        let dateRange = StatsDateRange(interval: interval, component: .day, comparison: .off, calendar: calendar)
        let viewModel = CustomDateRangePickerViewModel(dateRange: dateRange, calendar: calendar)

        // Initial count should be 6 days
        #expect(viewModel.formattedDateCount == "6 days")

        // WHEN - Move end date to Feb 2 (before current start date)
        // ViewModel should automatically adjust start date
        viewModel.endDate = Date("2026-02-02T00:00:00-03:00")

        // THEN - Start date should be automatically adjusted to Feb 1
        #expect(calendar.startOfDay(for: viewModel.startDate) == Date("2026-02-01T00:00:00-03:00"))

        // Count should now be 2 days (Feb 1-2)
        #expect(viewModel.formattedDateCount == "2 days")
    }

    @Test("Start date equals end date is valid")
    func startEqualsEndIsValid() {
        // GIVEN - Both dates set to Feb 3
        let interval = DateInterval(
            start: Date("2026-02-03T00:00:00-03:00"),
            end: Date("2026-02-04T00:00:00-03:00")
        )
        let dateRange = StatsDateRange(interval: interval, component: .day, comparison: .off, calendar: calendar)
        let viewModel = CustomDateRangePickerViewModel(dateRange: dateRange, calendar: calendar)

        // Initial count should be 1 day
        #expect(viewModel.formattedDateCount == "1 day")

        // THEN - Both dates should be on Feb 3 (same day)
        #expect(calendar.startOfDay(for: viewModel.startDate) == Date("2026-02-03T00:00:00-03:00"))
        #expect(calendar.startOfDay(for: viewModel.endDate) == Date("2026-02-03T00:00:00-03:00"))

        // Count should be 1 day
        #expect(viewModel.formattedDateCount == "1 day")
    }

    // MARK: - Create Date Interval Tests

    @Test("Create interval for single day")
    func createIntervalSingleDay() {
        // GIVEN - Feb 3 to Feb 3
        let interval = DateInterval(
            start: Date("2026-02-03T00:00:00-03:00"),
            end: Date("2026-02-04T00:00:00-03:00")
        )
        let dateRange = StatsDateRange(interval: interval, component: .day, comparison: .off, calendar: calendar)
        let viewModel = CustomDateRangePickerViewModel(dateRange: dateRange, calendar: calendar)

        // Formatted count should show "1 day"
        #expect(viewModel.formattedDateCount == "1 day")

        // WHEN
        let result = viewModel.createDateInterval()

        // THEN - Should create interval from Feb 3 00:00 to Feb 4 00:00 (inclusive of Feb 3)
        #expect(result.start == Date("2026-02-03T00:00:00-03:00"))
        #expect(result.end == Date("2026-02-04T00:00:00-03:00"))
    }

    @Test("Create interval for multiple days")
    func createIntervalMultipleDays() {
        // GIVEN - Feb 1 to Feb 5
        let interval = DateInterval(
            start: Date("2026-02-01T00:00:00-03:00"),
            end: Date("2026-02-06T00:00:00-03:00")
        )
        let dateRange = StatsDateRange(interval: interval, component: .day, comparison: .off, calendar: calendar)
        let viewModel = CustomDateRangePickerViewModel(dateRange: dateRange, calendar: calendar)

        // Formatted count should show "5 days"
        #expect(viewModel.formattedDateCount == "5 days")

        // WHEN
        let result = viewModel.createDateInterval()

        // THEN - Should create interval from Feb 1 00:00 to Feb 6 00:00 (inclusive of Feb 1-5)
        #expect(result.start == Date("2026-02-01T00:00:00-03:00"))
        #expect(result.end == Date("2026-02-06T00:00:00-03:00"))
    }

    @Test("Create interval normalizes end date to start of day")
    func createIntervalNormalizesToStartOfDay() {
        // GIVEN - Single day period (Feb 3)
        let interval = DateInterval(
            start: Date("2026-02-03T00:00:00-03:00"),
            end: Date("2026-02-04T00:00:00-03:00")
        )
        let dateRange = StatsDateRange(interval: interval, component: .day, comparison: .off, calendar: calendar)
        let viewModel = CustomDateRangePickerViewModel(dateRange: dateRange, calendar: calendar)

        // User picks a date with time component (e.g. from DatePicker)
        // Set end date to Feb 5 at a specific time
        viewModel.endDate = Date("2026-02-05T18:45:00-03:00")

        // Formatted count should show "3 days" (Feb 3, 4, 5)
        #expect(viewModel.formattedDateCount == "3 days")

        // WHEN - Create interval
        let result = viewModel.createDateInterval()

        // THEN - End should be normalized to start of next day (Feb 6 00:00)
        // This makes the period inclusive of Feb 3, 4, and 5
        #expect(result.start == Date("2026-02-03T00:00:00-03:00"))
        #expect(result.end == Date("2026-02-06T00:00:00-03:00"))
    }

    // MARK: - Quick Period Selection Tests

    @Test("Select week period")
    func selectWeekPeriod() {
        // GIVEN - Start date is Wednesday, Feb 5, 2026
        let interval = DateInterval(
            start: Date("2026-02-05T00:00:00-03:00"),
            end: Date("2026-02-06T00:00:00-03:00")
        )
        let dateRange = StatsDateRange(interval: interval, component: .day, comparison: .off, calendar: calendar)
        let viewModel = CustomDateRangePickerViewModel(dateRange: dateRange, calendar: calendar)

        // Initial count should be 1 day
        #expect(viewModel.formattedDateCount == "1 day")

        // WHEN - Select week period
        viewModel.selectQuickPeriod(.weekOfYear)

        // THEN - Should select the full week containing Feb 5
        // Week starts on Sunday (Feb 1) and ends on Sunday (Feb 8)
        #expect(viewModel.startDate == Date("2026-02-01T00:00:00-03:00"))
        #expect(calendar.startOfDay(for: viewModel.endDate) == Date("2026-02-07T00:00:00-03:00"))

        // Count should now be 7 days
        #expect(viewModel.formattedDateCount == "7 days")
    }

    @Test("Select month period")
    func selectMonthPeriod() {
        // GIVEN - Start date is Feb 15, 2026
        let interval = DateInterval(
            start: Date("2026-02-15T00:00:00-03:00"),
            end: Date("2026-02-16T00:00:00-03:00")
        )
        let dateRange = StatsDateRange(interval: interval, component: .day, comparison: .off, calendar: calendar)
        let viewModel = CustomDateRangePickerViewModel(dateRange: dateRange, calendar: calendar)

        // Initial count should be 1 day
        #expect(viewModel.formattedDateCount == "1 day")

        // WHEN - Select month period
        viewModel.selectQuickPeriod(.month)

        // THEN - Should select all of February 2026
        #expect(viewModel.startDate == Date("2026-02-01T00:00:00-03:00"))
        #expect(calendar.startOfDay(for: viewModel.endDate) == Date("2026-02-28T00:00:00-03:00"))

        // Count should now be 28 days (February 2026 is not a leap year)
        #expect(viewModel.formattedDateCount == "28 days")
    }

    @Test("Select quarter period")
    func selectQuarterPeriod() {
        // GIVEN - Start date is Feb 15, 2026 (Q1)
        let interval = DateInterval(
            start: Date("2026-02-15T00:00:00-03:00"),
            end: Date("2026-02-16T00:00:00-03:00")
        )
        let dateRange = StatsDateRange(interval: interval, component: .day, comparison: .off, calendar: calendar)
        let viewModel = CustomDateRangePickerViewModel(dateRange: dateRange, calendar: calendar)

        // Initial count should be 1 day
        #expect(viewModel.formattedDateCount == "1 day")

        // WHEN - Select quarter period
        viewModel.selectQuickPeriod(.quarter)

        // THEN - Should select Q1 (Jan 1 - Mar 31)
        #expect(viewModel.startDate == Date("2026-01-01T00:00:00-03:00"))
        #expect(calendar.startOfDay(for: viewModel.endDate) == Date("2026-03-31T00:00:00-03:00"))

        // Count should now be 90 days (Q1 2026: Jan 31 + Feb 28 + Mar 31)
        #expect(viewModel.formattedDateCount == "90 days")
    }

    @Test("Select year period")
    func selectYearPeriod() {
        // GIVEN - Start date is Feb 15, 2026
        let interval = DateInterval(
            start: Date("2026-02-15T00:00:00-03:00"),
            end: Date("2026-02-16T00:00:00-03:00")
        )
        let dateRange = StatsDateRange(interval: interval, component: .day, comparison: .off, calendar: calendar)
        let viewModel = CustomDateRangePickerViewModel(dateRange: dateRange, calendar: calendar)

        // Initial count should be 1 day
        #expect(viewModel.formattedDateCount == "1 day")

        // WHEN - Select year period
        viewModel.selectQuickPeriod(.year)

        // THEN - Should select all of 2026
        #expect(viewModel.startDate == Date("2026-01-01T00:00:00-03:00"))
        #expect(calendar.startOfDay(for: viewModel.endDate) == Date("2026-12-31T00:00:00-03:00"))

        // Count should now be 365 days (2026 is not a leap year)
        #expect(viewModel.formattedDateCount == "365 days")
    }

    // MARK: - Create Stats Date Range Tests

    @Test("Create stats date range for single day")
    func createStatsDateRangeSingleDay() {
        // GIVEN - Feb 3 to Feb 3
        let interval = DateInterval(
            start: Date("2026-02-03T00:00:00-03:00"),
            end: Date("2026-02-04T00:00:00-03:00")
        )
        let dateRange = StatsDateRange(interval: interval, component: .day, comparison: .precedingPeriod, calendar: calendar)
        let viewModel = CustomDateRangePickerViewModel(dateRange: dateRange, calendar: calendar)

        // WHEN
        let result = viewModel.createStatsDateRange()

        // THEN
        #expect(result.dateInterval.start == Date("2026-02-03T00:00:00-03:00"))
        #expect(result.dateInterval.end == Date("2026-02-04T00:00:00-03:00"))
        #expect(result.component == .day)
        #expect(result.comparison == .precedingPeriod)
        #expect(result.calendar == calendar)
    }

    @Test("Create stats date range for week")
    func createStatsDateRangeWeek() {
        // GIVEN - Start date is Feb 5, 2026
        let interval = DateInterval(
            start: Date("2026-02-05T00:00:00-03:00"),
            end: Date("2026-02-06T00:00:00-03:00")
        )
        let dateRange = StatsDateRange(interval: interval, component: .day, comparison: .samePeriodLastYear, calendar: calendar)
        let viewModel = CustomDateRangePickerViewModel(dateRange: dateRange, calendar: calendar)

        // Select full week
        viewModel.selectQuickPeriod(.weekOfYear)

        // WHEN
        let result = viewModel.createStatsDateRange()

        // THEN - Should create a week range
        #expect(result.dateInterval.start == Date("2026-02-01T00:00:00-03:00"))
        #expect(result.dateInterval.end == Date("2026-02-08T00:00:00-03:00"))
        #expect(result.component == .weekOfYear)
        #expect(result.comparison == .samePeriodLastYear)
    }

    @Test("Create stats date range for custom period")
    func createStatsDateRangeCustomPeriod() {
        // GIVEN - 10 day custom period
        let interval = DateInterval(
            start: Date("2026-02-01T00:00:00-03:00"),
            end: Date("2026-02-06T00:00:00-03:00")
        )
        let dateRange = StatsDateRange(interval: interval, component: .day, comparison: .off, calendar: calendar)
        let viewModel = CustomDateRangePickerViewModel(dateRange: dateRange, calendar: calendar)

        // Extend to 10 days
        viewModel.endDate = Date("2026-02-10T00:00:00-03:00")

        // WHEN
        let result = viewModel.createStatsDateRange()

        // THEN - Should create custom day-based range
        #expect(result.dateInterval.start == Date("2026-02-01T00:00:00-03:00"))
        #expect(result.dateInterval.end == Date("2026-02-11T00:00:00-03:00"))
        #expect(result.component == .day) // Custom periods use .day
        #expect(result.comparison == .off)
    }

    @Test("Create stats date range preserves comparison setting")
    func createStatsDateRangePreservesComparison() {
        // GIVEN - Date range with each comparison type
        let interval = DateInterval(
            start: Date("2026-02-01T00:00:00-03:00"),
            end: Date("2026-02-02T00:00:00-03:00")
        )

        for comparison in [DateRangeComparisonPeriod.precedingPeriod, .samePeriodLastYear, .off] {
            let dateRange = StatsDateRange(interval: interval, component: .day, comparison: comparison, calendar: calendar)
            let viewModel = CustomDateRangePickerViewModel(dateRange: dateRange, calendar: calendar)

            // WHEN
            let result = viewModel.createStatsDateRange()

            // THEN - Should preserve the comparison setting
            #expect(result.comparison == comparison)
        }
    }

    // MARK: - Edge Cases

    @Test("Leap year February")
    func leapYearFebruary() {
        // GIVEN - February 2024 (leap year)
        let interval = DateInterval(
            start: Date("2024-02-01T00:00:00-03:00"),
            end: Date("2024-03-01T00:00:00-03:00")
        )
        let dateRange = StatsDateRange(interval: interval, component: .month, comparison: .off, calendar: calendar)
        let viewModel = CustomDateRangePickerViewModel(dateRange: dateRange, calendar: calendar)

        // WHEN
        let formatted = viewModel.formattedDateCount

        // THEN - February 2024 has 29 days
        #expect(formatted == "29 days")
    }

    @Test("Year boundary crossing")
    func yearBoundaryCrossing() {
        // GIVEN - Dec 30 to Jan 2
        let interval = DateInterval(
            start: Date("2025-12-30T00:00:00-03:00"),
            end: Date("2026-01-03T00:00:00-03:00")
        )
        let dateRange = StatsDateRange(interval: interval, component: .day, comparison: .off, calendar: calendar)
        let viewModel = CustomDateRangePickerViewModel(dateRange: dateRange, calendar: calendar)

        // WHEN
        let formatted = viewModel.formattedDateCount
        let createdInterval = viewModel.createDateInterval()

        // THEN
        #expect(formatted == "4 days")
        #expect(createdInterval.start == Date("2025-12-30T00:00:00-03:00"))
        #expect(createdInterval.end == Date("2026-01-03T00:00:00-03:00"))
    }
}
