import Testing
import Foundation
@testable import JetpackStats

@Suite
struct StatsDateRangeFormatterTests {
    let calendar = Calendar.mock(timeZone: .eastern)
    let locale = Locale(identifier: "en_US")
    let now = Date("2025-07-15T10:00:00-03:00")
    let formatter = StatsDateRangeFormatter(
        locale: Locale(identifier: "en_US"),
        timeZone: .eastern,
        now: { Date("2025-07-15T10:00:00-03:00") }
    )

    // MARK: - Date Range Formatting

    @Test("Date range formatting", arguments: [
        // Single day
        (Date("2025-01-01T00:00:00-03:00"), Date("2025-01-02T00:00:00-03:00"), "Jan 1"),
        // Same month range
        (Date("2025-01-01T00:00:00-03:00"), Date("2025-01-06T00:00:00-03:00"), "Jan 1 – 5"),
        (Date("2025-01-03T00:00:00-03:00"), Date("2025-01-13T00:00:00-03:00"), "Jan 3 – 12"),
        // Cross month range
        (Date("2025-01-31T00:00:00-03:00"), Date("2025-02-03T00:00:00-03:00"), "Jan 31 – Feb 2"),
        // Cross year range
        (Date("2024-12-31T00:00:00-03:00"), Date("2025-01-03T00:00:00-03:00"), "Dec 31, 2024 – Jan 2, 2025"),
        // Same year, different months
        (Date("2025-03-15T00:00:00-03:00"), Date("2025-05-20T00:00:00-03:00"), "Mar 15 – May 19")
    ])
    func dateRangeFormatting(startDate: Date, endDate: Date, expected: String) {
        let interval = DateInterval(start: startDate, end: endDate)
        #expect(formatter.string(from: interval) == expected)
    }

    // MARK: - Special Period Formatting

    @Test("Entire month formatting", arguments: [
        (Date("2025-01-01T00:00:00-03:00"), Date("2025-02-01T00:00:00-03:00"), "Jan 2025"),
        (Date("2024-02-01T00:00:00-03:00"), Date("2024-03-01T00:00:00-03:00"), "Feb 2024"), // Leap year
        (Date("2023-12-01T00:00:00-03:00"), Date("2024-01-01T00:00:00-03:00"), "Dec 2023"),
        (Date("2025-04-01T00:00:00-03:00"), Date("2025-05-01T00:00:00-03:00"), "Apr 2025") // 30-day month
    ])
    func entireMonthFormatting(startDate: Date, endDate: Date, expected: String) {
        let interval = DateInterval(start: startDate, end: endDate)
        #expect(formatter.string(from: interval) == expected)
    }

    @Test("Multiple full months formatting", arguments: [
        // Two months
        (Date("2025-01-01T00:00:00-03:00"), Date("2025-03-01T00:00:00-03:00"), "Jan – Feb 2025"),
        // Three months
        (Date("2025-01-01T00:00:00-03:00"), Date("2025-04-01T00:00:00-03:00"), "Jan – Mar 2025"),
        // Five months
        (Date("2025-01-01T00:00:00-03:00"), Date("2025-06-01T00:00:00-03:00"), "Jan – May 2025"),
        // Cross-year multiple months
        (Date("2024-11-01T00:00:00-03:00"), Date("2025-02-01T00:00:00-03:00"), "Nov 2024 – Jan 2025"),
        // Full quarter
        (Date("2025-04-01T00:00:00-03:00"), Date("2025-07-01T00:00:00-03:00"), "Apr – Jun 2025"),
        // Most of year
        (Date("2025-02-01T00:00:00-03:00"), Date("2025-12-01T00:00:00-03:00"), "Feb – Nov 2025")
    ])
    func multipleFullMonthsFormatting(startDate: Date, endDate: Date, expected: String) {
        let interval = DateInterval(start: startDate, end: endDate)
        #expect(formatter.string(from: interval) == expected)
    }

    @Test("Entire week formatting", arguments: [
        // Monday to Monday (full week)
        (Date("2025-01-13T00:00:00-03:00"), Date("2025-01-20T00:00:00-03:00"), "Jan 13 – 19"),
        // Sunday to Sunday (full week starting Sunday)
        (Date("2025-01-12T00:00:00-03:00"), Date("2025-01-19T00:00:00-03:00"), "Jan 12 – 18"),
        // Week crossing months
        (Date("2025-01-27T00:00:00-03:00"), Date("2025-02-03T00:00:00-03:00"), "Jan 27 – Feb 2"),
        // Week crossing years
        (Date("2024-12-30T00:00:00-03:00"), Date("2025-01-06T00:00:00-03:00"), "Dec 30, 2024 – Jan 5, 2025")
    ])
    func entireWeekFormatting(startDate: Date, endDate: Date, expected: String) {
        let interval = DateInterval(start: startDate, end: endDate)
        #expect(formatter.string(from: interval) == expected)
    }

    @Test("Entire year formatting", arguments: [
        (Date("2025-01-01T00:00:00-03:00"), Date("2026-01-01T00:00:00-03:00"), "2025"),
        (Date("2024-01-01T00:00:00-03:00"), Date("2025-01-01T00:00:00-03:00"), "2024"),
        (Date("2000-01-01T00:00:00-03:00"), Date("2001-01-01T00:00:00-03:00"), "2000")
    ])
    func entireYearFormatting(startDate: Date, endDate: Date, expected: String) {
        let interval = DateInterval(start: startDate, end: endDate)
        #expect(formatter.string(from: interval) == expected)
    }

    @Test("Multiple full years formatting", arguments: [
        // Two years
        (Date("2023-01-01T00:00:00-03:00"), Date("2025-01-01T00:00:00-03:00"), "2023 – 2024"),
        // Three years
        (Date("2020-01-01T00:00:00-03:00"), Date("2023-01-01T00:00:00-03:00"), "2020 – 2022"),
        // Four years
        (Date("2020-01-01T00:00:00-03:00"), Date("2024-01-01T00:00:00-03:00"), "2020 – 2023"),
        // Ten years
        (Date("2015-01-01T00:00:00-03:00"), Date("2025-01-01T00:00:00-03:00"), "2015 – 2024"),
        // Century boundary
        (Date("1999-01-01T00:00:00-03:00"), Date("2002-01-01T00:00:00-03:00"), "1999 – 2001")
    ])
    func multipleFullYearsFormatting(startDate: Date, endDate: Date, expected: String) {
        let interval = DateInterval(start: startDate, end: endDate)
        #expect(formatter.string(from: interval) == expected)
    }

    // MARK: - Current vs Previous Year Tests

    @Test("Same year as current year formatting")
    func sameYearAsCurrentFormatting() {
        let testNow = Date("2025-07-15T10:00:00-03:00") // Fixed date in 2025

        // Single day in current year - no year shown
        let singleDay = DateInterval(start: Date("2025-03-15T00:00:00-03:00"), end: Date("2025-03-16T00:00:00-03:00"))
        #expect(formatter.string(from: singleDay, now: testNow) == "Mar 15")

        // Range within current year - no year shown
        let rangeInYear = DateInterval(start: Date("2025-05-01T00:00:00-03:00"), end: Date("2025-05-08T00:00:00-03:00"))
        #expect(formatter.string(from: rangeInYear, now: testNow) == "May 1 – 7")

        // Cross month range in current year - no year shown
        let crossMonth = DateInterval(start: Date("2025-06-28T00:00:00-03:00"), end: Date("2025-07-03T00:00:00-03:00"))
        #expect(formatter.string(from: crossMonth, now: testNow) == "Jun 28 – Jul 2")
    }

    @Test("Previous year formatting")
    func previousYearFormatting() {
        let testNow = Date("2025-07-15T10:00:00-03:00") // Fixed date in 2025

        // Single day in previous year - year shown
        let singleDay = DateInterval(start: Date("2024-03-15T00:00:00-03:00"), end: Date("2024-03-16T00:00:00-03:00"))
        #expect(formatter.string(from: singleDay, now: testNow) == "Mar 15, 2024")

        // Range within previous year - year shown at end
        let rangeInYear = DateInterval(start: Date("2024-05-01T00:00:00-03:00"), end: Date("2024-05-08T00:00:00-03:00"))
        #expect(formatter.string(from: rangeInYear, now: testNow) == "May 1 – 7, 2024")

        // Cross month range in previous year - year shown at end
        let crossMonth = DateInterval(start: Date("2024-06-28T00:00:00-03:00"), end: Date("2024-07-03T00:00:00-03:00"))
        #expect(formatter.string(from: crossMonth, now: testNow) == "Jun 28 – Jul 2, 2024")
    }

    @Test("Cross year formatting with current year")
    func crossYearWithCurrentFormatting() {
        let testNow = Date("2025-07-15T10:00:00-03:00") // Fixed date in 2025

        // Range from previous to current year - both years shown
        let crossYear = DateInterval(start: Date("2024-12-28T00:00:00-03:00"), end: Date("2025-01-03T00:00:00-03:00"))
        #expect(formatter.string(from: crossYear, now: testNow) == "Dec 28, 2024 – Jan 2, 2025")
    }

    // MARK: - DateRangePreset Integration Tests

    @Test("DateRangePreset formatting - current year", arguments: [
        (DateIntervalPreset.today, "Mar 15"),
        (DateIntervalPreset.thisWeek, "Mar 9 – 15"),
        (DateIntervalPreset.thisMonth, "Mar 2025"),
        (DateIntervalPreset.thisYear, "2025"),
        (DateIntervalPreset.last7Days, "Mar 8 – 14"),
        (DateIntervalPreset.last30Days, "Feb 13 – Mar 14")
    ])
    func dateRangePresetFormattingCurrentYear(preset: DateIntervalPreset, expected: String) {
        // Set up a specific date in 2025
        let testNow = Date("2025-03-15T14:30:00-03:00")

        let interval = calendar.makeDateInterval(for: preset, now: testNow)
        #expect(formatter.string(from: interval, now: testNow) == expected)
    }

    @Test("DateRangePreset formatting - year boundaries")
    func dateRangePresetFormattingYearBoundaries() {
        // Test date near year boundary - January 5, 2025
        let testNow = Date("2025-01-05T10:00:00-03:00")

        // Last 30 days crosses year boundary
        let last30Days = calendar.makeDateInterval(for: .last30Days, now: testNow)
        #expect(formatter.string(from: last30Days, now: testNow) == "Dec 6, 2024 – Jan 4, 2025")
    }

    @Test("DateRangePreset formatting - custom ranges")
    func dateRangePresetFormattingCustomRanges() {
        // Custom single day
        let customDay = DateInterval(
            start: Date("2025-06-10T00:00:00-03:00"),
            end: Date("2025-06-11T00:00:00-03:00")
        )
        #expect(formatter.string(from: customDay, now: now) == "Jun 10")

        // Custom range in same month
        let customRange = DateInterval(
            start: Date("2025-06-05T00:00:00-03:00"),
            end: Date("2025-06-15T00:00:00-03:00")
        )
        #expect(formatter.string(from: customRange) == "Jun 5 – 14")

        // Custom range across months
        let customCrossMonth = DateInterval(
            start: Date("2025-05-25T00:00:00-03:00"),
            end: Date("2025-06-05T00:00:00-03:00")
        )
        #expect(formatter.string(from: customCrossMonth) == "May 25 – Jun 4")
    }

    // MARK: - Localization Tests

    @Test("Different locales", arguments: [
        ("en_US", Date("2025-01-15T00:00:00-03:00"), Date("2025-01-16T00:00:00-03:00"), "Jan 15"),
        ("es_ES", Date("2025-01-15T00:00:00-03:00"), Date("2025-01-16T00:00:00-03:00"), "15 ene"),
        ("fr_FR", Date("2025-01-15T00:00:00-03:00"), Date("2025-01-16T00:00:00-03:00"), "15 janv."),
        ("de_DE", Date("2025-01-15T00:00:00-03:00"), Date("2025-01-16T00:00:00-03:00"), "15. Jan.")
    ])
    func differentLocales(localeId: String, startDate: Date, endDate: Date, expected: String) {
        let locale = Locale(identifier: localeId)
        let interval = DateInterval(start: startDate, end: endDate)
        let formatter = StatsDateRangeFormatter(
            locale: locale,
            timeZone: calendar.timeZone,
            now: { Date("2025-07-15T10:00:00-03:00") }
        )
        #expect(formatter.string(from: interval) == expected)
    }
}
