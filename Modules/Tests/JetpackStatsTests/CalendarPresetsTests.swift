import Testing
import Foundation
@testable import JetpackStats

@Suite
struct CalendarDateRangePresetTests {
    let calendar = Calendar.mock(timeZone: .eastern)

    @Test("Date range presets", arguments: [
        (DateIntervalPreset.today, Date("2025-01-15T00:00:00-03:00"), Date("2025-01-16T00:00:00-03:00")),
        (.thisWeek, Date("2025-01-12T00:00:00-03:00"), Date("2025-01-19T00:00:00-03:00")),
        (.thisMonth, Date("2025-01-01T00:00:00-03:00"), Date("2025-02-01T00:00:00-03:00")),
        (.thisQuarter, Date("2025-01-01T00:00:00-03:00"), Date("2025-04-01T00:00:00-03:00")),
        (.thisYear, Date("2025-01-01T00:00:00-03:00"), Date("2026-01-01T00:00:00-03:00")),
        (.last7Days, Date("2025-01-08T00:00:00-03:00"), Date("2025-01-15T00:00:00-03:00")),
        (.last28Days, Date("2024-12-18T00:00:00-03:00"), Date("2025-01-15T00:00:00-03:00")),
        (.last30Days, Date("2024-12-16T00:00:00-03:00"), Date("2025-01-15T00:00:00-03:00")),
        (.last90Days, Date("2024-10-17T00:00:00-03:00"), Date("2025-01-15T00:00:00-03:00")),
        (.last6Months, Date("2024-08-01T00:00:00-03:00"), Date("2025-02-01T00:00:00-03:00")),
        (.last12Months, Date("2024-02-01T00:00:00-03:00"), Date("2025-02-01T00:00:00-03:00")),
        (.last3Years, Date("2023-01-01T00:00:00-03:00"), Date("2026-01-01T00:00:00-03:00")),
        (.last10Years, Date("2016-01-01T00:00:00-03:00"), Date("2026-01-01T00:00:00-03:00"))
    ])
    func dateRangePresets(preset: DateIntervalPreset, expectedStart: Date, expectedEnd: Date) {
        // GIVEN
        let now = Date("2025-01-15T14:30:00-03:00")
        let interval = calendar.makeDateInterval(for: preset, now: now)

        // THEN
        #expect(interval.start == expectedStart)
        #expect(interval.end == expectedEnd)
    }

    // MARK: - Edge Cases

    @Test("Preset handles leap year February correctly")
    func presetLeapYearFebruary() {
        // GIVEN - Date in February of leap year
        let now = Date("2024-02-15T14:30:00-03:00")

        // WHEN
        let monthToDate = calendar.makeDateInterval(for: .thisMonth, now: now)

        // THEN - Should include all 29 days
        #expect(monthToDate.start == Date("2024-02-01T00:00:00-03:00"))
        #expect(monthToDate.end == Date("2024-03-01T00:00:00-03:00"))
    }

    @Test("Preset handles year boundary correctly", arguments: [
        (DateIntervalPreset.last7Days, Date("2024-12-29T00:00:00-03:00"), Date("2025-01-05T00:00:00-03:00")),
        (DateIntervalPreset.last30Days, Date("2024-12-06T00:00:00-03:00"), Date("2025-01-05T00:00:00-03:00"))
    ])
    func presetYearBoundary(preset: DateIntervalPreset, expectedStart: Date, expectedEnd: Date) {
        // GIVEN
        let now = Date("2025-01-05T14:30:00-03:00")

        // WHEN
        let interval = calendar.makeDateInterval(for: preset, now: now)

        // THEN
        #expect(interval.start == expectedStart)
        #expect(interval.end == expectedEnd)
    }

    @Test("Preset handles daylight saving time transitions")
    func presetDSTTransition() {
        // GIVEN - Using UTC to avoid DST complications in tests
        let utcCalendar = Calendar.mock(timeZone: TimeZone(secondsFromGMT: 0)!)
        let beforeDST = Date("2024-03-09T12:00:00Z") // Day before DST in US
        let afterDST = Date("2024-03-11T12:00:00Z") // Day after DST in US

        // WHEN
        let intervalBefore = utcCalendar.makeDateInterval(for: .today, now: beforeDST)
        let intervalAfter = utcCalendar.makeDateInterval(for: .today, now: afterDST)

        // THEN - Both should be exactly 24 hours
        #expect(intervalBefore.duration == 86400)
        #expect(intervalAfter.duration == 86400)
    }

    // MARK: - Time Zone Tests

    @Test("Presets work correctly across different time zones", arguments: [
        (TimeZone(secondsFromGMT: 0)!, Date("2025-01-15T00:00:00Z")),
        (TimeZone(secondsFromGMT: 6 * 3600)!, Date("2025-01-15T00:00:00+06:00")),
        (TimeZone(secondsFromGMT: 12 * 3600)!, Date("2025-01-16T00:00:00+12:00")),
        (TimeZone(secondsFromGMT: 18 * 3600)!, Date("2025-01-16T00:00:00+18:00")),
        (TimeZone(secondsFromGMT: -6 * 3600)!, Date("2025-01-15T00:00:00-06:00")),
        (TimeZone(secondsFromGMT: -12 * 3600)!, Date("2025-01-15T00:00:00-12:00")),
        (TimeZone(secondsFromGMT: -18 * 3600)!, Date("2025-01-14T00:00:00-18:00"))
    ])
    func presetsWithDifferentTimeZones(timeZone: TimeZone, expectedStart: Date) {
        // GIVEN reporting time zone is differnet from your current time zone (UTC)
        let calendar = Calendar.mock(timeZone: timeZone)

        // GIVEN it's 3 PM in UTC (your current time zone)
        let now = Date("2025-01-15T15:00:00Z")

        // WHEN
        let interval = calendar.makeDateInterval(for: .today, now: now)

        // THEN "today" is picked according to your site reporting time zone
        // and not your local time zone
        #expect(interval.start == expectedStart)
    }

    // MARK: - Edge Cases for All Presets

    @Test("All presets handle month boundaries correctly", arguments: [
        (DateIntervalPreset.today, Date("2025-01-31T00:00:00-03:00"), Date("2025-02-01T00:00:00-03:00")),
        (.thisWeek, Date("2025-01-26T00:00:00-03:00"), Date("2025-02-02T00:00:00-03:00")),
        (.thisMonth, Date("2025-01-01T00:00:00-03:00"), Date("2025-02-01T00:00:00-03:00")),
        (.thisQuarter, Date("2025-01-01T00:00:00-03:00"), Date("2025-04-01T00:00:00-03:00")),
        (.thisYear, Date("2025-01-01T00:00:00-03:00"), Date("2026-01-01T00:00:00-03:00")),
        (.last7Days, Date("2025-01-24T00:00:00-03:00"), Date("2025-01-31T00:00:00-03:00")),
        (.last28Days, Date("2025-01-03T00:00:00-03:00"), Date("2025-01-31T00:00:00-03:00")),
        (.last30Days, Date("2025-01-01T00:00:00-03:00"), Date("2025-01-31T00:00:00-03:00")),
        (.last90Days, Date("2024-11-02T00:00:00-03:00"), Date("2025-01-31T00:00:00-03:00")),
        (.last6Months, Date("2024-08-01T00:00:00-03:00"), Date("2025-02-01T00:00:00-03:00")),
        (.last12Months, Date("2024-02-01T00:00:00-03:00"), Date("2025-02-01T00:00:00-03:00")),
        (.last3Years, Date("2023-01-01T00:00:00-03:00"), Date("2026-01-01T00:00:00-03:00")),
        (.last10Years, Date("2016-01-01T00:00:00-03:00"), Date("2026-01-01T00:00:00-03:00"))
    ])
    func allPresetsMonthBoundaries(preset: DateIntervalPreset, expectedStart: Date, expectedEnd: Date) {
        // GIVEN today is the last day of the month
        let endOfMonth = Date("2025-01-31T14:30:00-03:00")

        // WHEN
        let interval = calendar.makeDateInterval(for: preset, now: endOfMonth)

        // THEN
        #expect(interval.start == expectedStart)
        #expect(interval.end == expectedEnd)
    }

    @Test("All presets handle year boundaries correctly", arguments: [
        (DateIntervalPreset.today, Date("2025-01-01T00:00:00-03:00"), Date("2025-01-02T00:00:00-03:00")),
        (.thisWeek, Date("2024-12-29T00:00:00-03:00"), Date("2025-01-05T00:00:00-03:00")),
        (.thisMonth, Date("2025-01-01T00:00:00-03:00"), Date("2025-02-01T00:00:00-03:00")),
        (.thisQuarter, Date("2025-01-01T00:00:00-03:00"), Date("2025-04-01T00:00:00-03:00")),
        (.thisYear, Date("2025-01-01T00:00:00-03:00"), Date("2026-01-01T00:00:00-03:00")),
        (.last7Days, Date("2024-12-25T00:00:00-03:00"), Date("2025-01-01T00:00:00-03:00")),
        (.last28Days, Date("2024-12-04T00:00:00-03:00"), Date("2025-01-01T00:00:00-03:00")),
        (.last30Days, Date("2024-12-02T00:00:00-03:00"), Date("2025-01-01T00:00:00-03:00")),
        (.last90Days, Date("2024-10-03T00:00:00-03:00"), Date("2025-01-01T00:00:00-03:00")),
        (.last6Months, Date("2024-08-01T00:00:00-03:00"), Date("2025-02-01T00:00:00-03:00")),
        (.last12Months, Date("2024-02-01T00:00:00-03:00"), Date("2025-02-01T00:00:00-03:00")),
        (.last3Years, Date("2023-01-01T00:00:00-03:00"), Date("2026-01-01T00:00:00-03:00")),
        (.last10Years, Date("2016-01-01T00:00:00-03:00"), Date("2026-01-01T00:00:00-03:00"))
    ])
    func allPresetsYearBoundaries(preset: DateIntervalPreset, expectedStart: Date, expectedEnd: Date) {
        // GIVEN today is the first day of the year
        let startOfYear = Date("2025-01-01T14:30:00-03:00")

        // WHEN
        let interval = calendar.makeDateInterval(for: preset, now: startOfYear)

        // THEN
        #expect(interval.start == expectedStart)
        #expect(interval.end == expectedEnd)
    }

    // MARK: - Duration Tests

    @Test("DateInterval durations are calculated correctly")
    func intervalDurations() {
        // GIVEN
        let now = Date("2025-01-15T14:30:00-03:00")

        // Single day
        let day = calendar.makeDateInterval(for: .today, now: now)
        #expect(abs(day.duration - 86400) < 2) // ~24 hours

        // Week
        let week = calendar.makeDateInterval(for: .last7Days, now: now)
        #expect(abs(week.duration - (86400 * 7)) < 8) // ~7 days

        // Month (30 days)
        let month = calendar.makeDateInterval(for: .last30Days, now: now)
        #expect(abs(month.duration - (86400 * 30)) < 31) // ~30 days
    }

    // MARK: - Quarter Tests

    @Test("Quarter calculations work correctly", arguments: [
        // Q1: Jan-Mar
        (Date("2025-01-15T14:30:00-03:00"), Date("2025-01-01T00:00:00-03:00"), Date("2025-04-01T00:00:00-03:00")),
        (Date("2025-02-28T14:30:00-03:00"), Date("2025-01-01T00:00:00-03:00"), Date("2025-04-01T00:00:00-03:00")),
        (Date("2025-03-31T14:30:00-03:00"), Date("2025-01-01T00:00:00-03:00"), Date("2025-04-01T00:00:00-03:00")),
        // Q2: Apr-Jun
        (Date("2025-04-01T14:30:00-03:00"), Date("2025-04-01T00:00:00-03:00"), Date("2025-07-01T00:00:00-03:00")),
        (Date("2025-05-15T14:30:00-03:00"), Date("2025-04-01T00:00:00-03:00"), Date("2025-07-01T00:00:00-03:00")),
        (Date("2025-06-30T14:30:00-03:00"), Date("2025-04-01T00:00:00-03:00"), Date("2025-07-01T00:00:00-03:00")),
        // Q3: Jul-Sep
        (Date("2025-07-01T14:30:00-03:00"), Date("2025-07-01T00:00:00-03:00"), Date("2025-10-01T00:00:00-03:00")),
        (Date("2025-08-15T14:30:00-03:00"), Date("2025-07-01T00:00:00-03:00"), Date("2025-10-01T00:00:00-03:00")),
        (Date("2025-09-30T14:30:00-03:00"), Date("2025-07-01T00:00:00-03:00"), Date("2025-10-01T00:00:00-03:00")),
        // Q4: Oct-Dec
        (Date("2025-10-01T14:30:00-03:00"), Date("2025-10-01T00:00:00-03:00"), Date("2026-01-01T00:00:00-03:00")),
        (Date("2025-11-15T14:30:00-03:00"), Date("2025-10-01T00:00:00-03:00"), Date("2026-01-01T00:00:00-03:00")),
        (Date("2025-12-31T14:30:00-03:00"), Date("2025-10-01T00:00:00-03:00"), Date("2026-01-01T00:00:00-03:00"))
    ])
    func quarterCalculations(now: Date, expectedStart: Date, expectedEnd: Date) {
        // WHEN
        let interval = calendar.makeDateInterval(for: .thisQuarter, now: now)

        // THEN
        #expect(interval.start == expectedStart)
        #expect(interval.end == expectedEnd)
    }

    // MARK: - Special Date Tests

    @Test("Presets at exact midnight")
    func presetsAtMidnight() {
        // GIVEN
        let midnight = Date("2025-01-15T00:00:00-03:00")

        // WHEN
        let interval = calendar.makeDateInterval(for: .today, now: midnight)

        // THEN
        #expect(interval.start == Date("2025-01-15T00:00:00-03:00"))
        #expect(interval.end == Date("2025-01-16T00:00:00-03:00"))
    }

    @Test("Presets handle very old dates")
    func presetsWithOldDates() {
        // GIVEN - Date from year 2000
        let oldDate = Date("2000-06-15T14:30:00-03:00")

        // WHEN
        let threeYears = calendar.makeDateInterval(for: .last3Years, now: oldDate)

        // THEN
        #expect(threeYears.start == Date("1998-01-01T00:00:00-03:00"))
        #expect(threeYears.end == Date("2001-01-01T00:00:00-03:00"))
    }
}
