import Testing
import Foundation
@testable import JetpackStats

@Suite
struct CalendarNavigationTests {
    let calendar = Calendar.mock(timeZone: .eastern)
    let now = Date("2025-01-15T14:30:00-03:00")

    // MARK: - Calendar-Based Navigation

    @Test("Navigate single day forward")
    func navigateSingleDayForward() {
        // GIVEN
        let interval = DateInterval(
            start: Date("2025-01-15T00:00:00-03:00"),
            end: Date("2025-01-16T00:00:00-03:00")
        )

        // WHEN
        let result = calendar.navigate(interval, direction: .forward, component: .day)

        // THEN
        #expect(result.start == Date("2025-01-16T00:00:00-03:00"))
        #expect(result.end == Date("2025-01-17T00:00:00-03:00"))
    }

    @Test("Navigate single day backward")
    func navigateSingleDayBackward() {
        // GIVEN
        let interval = DateInterval(
            start: Date("2025-01-15T00:00:00-03:00"),
            end: Date("2025-01-16T00:00:00-03:00")
        )

        // WHEN
        let result = calendar.navigate(interval, direction: .backward, component: .day)

        // THEN
        #expect(result.start == Date("2025-01-14T00:00:00-03:00"))
        #expect(result.end == Date("2025-01-15T00:00:00-03:00"))
    }

    @Test("Navigate month forward")
    func navigateMonthForward() {
        // GIVEN
        let interval = DateInterval(
            start: Date("2025-01-01T00:00:00-03:00"),
            end: Date("2025-02-01T00:00:00-03:00")
        )

        // WHEN
        let result = calendar.navigate(interval, direction: .forward, component: .month)

        // THEN
        #expect(result.start == Date("2025-02-01T00:00:00-03:00"))
        #expect(result.end == Date("2025-03-01T00:00:00-03:00"))
    }

    @Test("Navigate year forward")
    func navigateYearForward() {
        // GIVEN
        let interval = DateInterval(
            start: Date("2024-01-01T00:00:00-03:00"),
            end: Date("2025-01-01T00:00:00-03:00")
        )

        // WHEN
        let result = calendar.navigate(interval, direction: .forward, component: .year)

        // THEN
        #expect(result.start == Date("2025-01-01T00:00:00-03:00"))
        #expect(result.end == Date("2026-01-01T00:00:00-03:00"))
    }

    @Test("Navigate week forward")
    func navigateWeekForward() {
        // GIVEN
        let interval = DateInterval(
            start: Date("2025-01-12T00:00:00-03:00"),
            end: Date("2025-01-19T00:00:00-03:00")
        )

        // WHEN
        let result = calendar.navigate(interval, direction: .forward, component: .weekOfYear)

        // THEN
        #expect(result.start == Date("2025-01-19T00:00:00-03:00"))
        #expect(result.end == Date("2025-01-26T00:00:00-03:00"))
    }

    @Test("Navigate month backward")
    func navigateMonthBackward() {
        // GIVEN
        let interval = DateInterval(
            start: Date("2025-02-01T00:00:00-03:00"),
            end: Date("2025-03-01T00:00:00-03:00")
        )

        // WHEN
        let result = calendar.navigate(interval, direction: .backward, component: .month)

        // THEN
        #expect(result.start == Date("2025-01-01T00:00:00-03:00"))
        #expect(result.end == Date("2025-02-01T00:00:00-03:00"))
    }

    @Test("Navigate year backward")
    func navigateYearBackward() {
        // GIVEN
        let interval = DateInterval(
            start: Date("2025-01-01T00:00:00-03:00"),
            end: Date("2026-01-01T00:00:00-03:00")
        )

        // WHEN
        let result = calendar.navigate(interval, direction: .backward, component: .year)

        // THEN
        #expect(result.start == Date("2024-01-01T00:00:00-03:00"))
        #expect(result.end == Date("2025-01-01T00:00:00-03:00"))
    }

    @Test("Navigate week backward")
    func navigateWeekBackward() {
        // GIVEN
        let interval = DateInterval(
            start: Date("2025-01-19T00:00:00-03:00"),
            end: Date("2025-01-26T00:00:00-03:00")
        )

        // WHEN
        let result = calendar.navigate(interval, direction: .backward, component: .weekOfYear)

        // THEN
        #expect(result.start == Date("2025-01-12T00:00:00-03:00"))
        #expect(result.end == Date("2025-01-19T00:00:00-03:00"))
    }

    // MARK: - Custom Period

    @Test("Navigate custom period (7 days)")
    func navigateCustomPeriod() {
        // GIVEN - 7 day period
        let interval = DateInterval(
            start: Date("2025-01-10T00:00:00-03:00"),
            end: Date("2025-01-17T00:00:00-03:00")
        )

        // WHEN
        let next = calendar.navigate(interval, direction: .forward, component: .day)
        let previous = calendar.navigate(interval, direction: .backward, component: .day)

        // THEN - Should shift by exactly 7 days
        #expect(next.start == Date("2025-01-17T00:00:00-03:00"))
        #expect(next.end == Date("2025-01-24T00:00:00-03:00"))

        #expect(previous.start == Date("2025-01-03T00:00:00-03:00"))
        #expect(previous.end == Date("2025-01-10T00:00:00-03:00"))
    }

    @Test("Navigate preserves duration", arguments: [
        (3, Date("2025-01-10T00:00:00-03:00"), Date("2025-01-13T00:00:00-03:00")),
        (7, Date("2025-01-10T00:00:00-03:00"), Date("2025-01-17T00:00:00-03:00")),
        (15, Date("2025-01-10T00:00:00-03:00"), Date("2025-01-25T00:00:00-03:00")),
        (30, Date("2025-01-01T00:00:00-03:00"), Date("2025-01-31T00:00:00-03:00"))
    ])
    func navigatePreservesDuration(days: Int, startDate: Date, endDate: Date) {
        // GIVEN
        let interval = DateInterval(start: startDate, end: endDate)
        let originalDuration = interval.duration

        // WHEN
        let next = calendar.navigate(interval, direction: .forward, component: .day)
        let previous = calendar.navigate(interval, direction: .backward, component: .day)

        // THEN - Duration should be preserved (within 1 second tolerance for DST)
        #expect(abs(next.duration - originalDuration) < 1)
        #expect(abs(previous.duration - originalDuration) < 1)
    }

    // MARK: - Can Navigate Tests

    @Test("Can navigate to previous checks year boundary", arguments: [
        (2001, Date("2001-01-15T00:00:00-03:00"), true, 2000),
        (2000, Date("2000-01-15T00:00:00-03:00"), false, 2000),
        (1999, Date("1999-01-15T00:00:00-03:00"), false, 2000),
        (2000, Date("2000-01-15T00:00:00-03:00"), true, 1999),
        (1999, Date("1999-01-15T00:00:00-03:00"), false, 1999)
    ])
    func canNavigateToPreviousYear(year: Int, date: Date, expectedResult: Bool, minYear: Int) {
        // GIVEN
        let interval = DateInterval(
            start: date,
            end: calendar.date(byAdding: .day, value: 1, to: date)!
        )

        // WHEN/THEN
        #expect(calendar.canNavigate(interval, direction: .backward, minYear: minYear) == expectedResult)
    }

    @Test("Can navigate to next checks against today")
    func canNavigateToNextToday() {
        // GIVEN
        let today = Date("2025-01-10T00:00:00-03:00")
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        let intervalYesterday = DateInterval(
            start: calendar.startOfDay(for: yesterday),
            end: calendar.startOfDay(for: today)
        )
        let intervalToday = DateInterval(
            start: calendar.startOfDay(for: today),
            end: calendar.startOfDay(for: tomorrow)
        )
        let intervalTomorrow = DateInterval(
            start: calendar.startOfDay(for: tomorrow),
            end: calendar.date(byAdding: .day, value: 1, to: tomorrow)!
        )

        // WHEN/THEN
        #expect(calendar.canNavigate(intervalYesterday, direction: .forward, now: today))
        #expect(!calendar.canNavigate(intervalToday, direction: .forward, now: today))
        #expect(!calendar.canNavigate(intervalTomorrow, direction: .forward, now: today))
    }

    // MARK: - Preset Navigation Tests

    @Test("Navigate preset intervals correctly", arguments: [
        // 6-month period should navigate by 6 months
        (Date("2024-08-01T00:00:00-03:00"), Date("2025-02-01T00:00:00-03:00"), Calendar.Component.month,
         Date("2024-02-01T00:00:00-03:00"), Date("2024-08-01T00:00:00-03:00")),
        // 12-month period should navigate by 12 months
        (Date("2024-02-01T00:00:00-03:00"), Date("2025-02-01T00:00:00-03:00"), Calendar.Component.month,
         Date("2023-02-01T00:00:00-03:00"), Date("2024-02-01T00:00:00-03:00")),
        // 5-year period should navigate by 5 years
        (Date("2021-01-01T00:00:00-03:00"), Date("2026-01-01T00:00:00-03:00"), Calendar.Component.year,
         Date("2016-01-01T00:00:00-03:00"), Date("2021-01-01T00:00:00-03:00")),
        // 7-day period should navigate by 7 days
        (Date("2025-01-08T00:00:00-03:00"), Date("2025-01-15T00:00:00-03:00"), Calendar.Component.day,
         Date("2025-01-01T00:00:00-03:00"), Date("2025-01-08T00:00:00-03:00"))
    ])
    func navigatePresetIntervals(startDate: Date, endDate: Date, component: Calendar.Component,
                                 expectedPrevStart: Date, expectedPrevEnd: Date) {
        // GIVEN - An interval representing a preset period
        let interval = DateInterval(start: startDate, end: endDate)

        // WHEN - Navigate backward
        let previous = calendar.navigate(interval, direction: .backward, component: component)

        // THEN - Should navigate by the period length
        #expect(previous.start == expectedPrevStart)
        #expect(previous.end == expectedPrevEnd)
    }

    // MARK: - Edge Case Tests

    @Test("Navigate handles boundary transitions", arguments: [
        // Leap year February - 29 days should navigate to another 29-day period
        (Date("2024-02-01T00:00:00-03:00"), Date("2024-03-01T00:00:00-03:00"), Date("2024-03-01T00:00:00-03:00"), Date("2024-03-30T00:00:00-03:00")),
        // Year boundary - 31 days should navigate to another 31-day period
        (Date("2024-12-01T00:00:00-03:00"), Date("2025-01-01T00:00:00-03:00"), Date("2025-01-01T00:00:00-03:00"), Date("2025-02-01T00:00:00-03:00")),
        // Week at year boundary - 7 days should navigate to another 7-day period
        (Date("2024-12-29T00:00:00-03:00"), Date("2025-01-05T00:00:00-03:00"), Date("2025-01-05T00:00:00-03:00"), Date("2025-01-12T00:00:00-03:00"))
    ])
    func navigateBoundaryTransitions(startDate: Date, endDate: Date, expectedStart: Date, expectedEnd: Date) {
        // GIVEN
        let interval = DateInterval(start: startDate, end: endDate)

        // WHEN - Navigate with day component
        let next = calendar.navigate(interval, direction: .forward, component: .day)

        // THEN
        #expect(next.start == expectedStart)
        #expect(next.end == expectedEnd)
    }

    @Test("Navigate partial periods by duration", arguments: [
        // 15-day partial month period
        (15, Date("2025-01-10T00:00:00-03:00"), Date("2025-01-25T00:00:00-03:00"), Date("2025-01-25T00:00:00-03:00"), Date("2025-02-09T00:00:00-03:00")),
        // 5-day partial week period
        (5, Date("2025-01-13T00:00:00-03:00"), Date("2025-01-18T00:00:00-03:00"), Date("2025-01-18T00:00:00-03:00"), Date("2025-01-23T00:00:00-03:00")),
        // Custom 10-day period
        (10, Date("2025-01-05T00:00:00-03:00"), Date("2025-01-15T00:00:00-03:00"), Date("2025-01-15T00:00:00-03:00"), Date("2025-01-25T00:00:00-03:00"))
    ])
    func navigatePartialPeriods(days: Int, startDate: Date, endDate: Date, expectedStart: Date, expectedEnd: Date) {
        // GIVEN
        let interval = DateInterval(start: startDate, end: endDate)

        // WHEN
        let next = calendar.navigate(interval, direction: .forward, component: .day)

        // THEN - Should navigate by the number of days
        #expect(next.start == expectedStart)
        #expect(next.end == expectedEnd)

        // Verify duration is preserved
        #expect(abs(next.duration - interval.duration) < 1)
    }

    // MARK: - Navigation Without Components Tests

    @Test("Navigate with component uses calendar-based navigation")
    func navigateWithComponentUsesCalendarNavigation() {
        // GIVEN - Various intervals that happen to align with calendar boundaries
        let fullMonth = DateInterval(
            start: Date("2025-02-01T00:00:00-03:00"),
            end: Date("2025-03-01T00:00:00-03:00")
        )
        let fullYear = DateInterval(
            start: Date("2025-01-01T00:00:00-03:00"),
            end: Date("2026-01-01T00:00:00-03:00")
        )

        // WHEN - Navigate with appropriate components
        let monthNext = calendar.navigate(fullMonth, direction: .forward, component: .month)
        let yearNext = calendar.navigate(fullYear, direction: .forward, component: .year)

        // THEN - Should navigate by calendar unit
        #expect(monthNext.start == Date("2025-03-01T00:00:00-03:00"))
        #expect(monthNext.end == Date("2025-04-01T00:00:00-03:00")) // Next month

        // Year interval navigated by 1 year
        #expect(yearNext.start == Date("2026-01-01T00:00:00-03:00"))
        #expect(yearNext.end == Date("2027-01-01T00:00:00-03:00"))
    }

    // MARK: - Week Navigation Tests

    @Test("Navigate week with component at year boundary")
    func navigateWeekYearBoundary() {
        // GIVEN - Week that crosses year boundary
        let interval = DateInterval(
            start: Date("2024-12-29T00:00:00-03:00"), // Sunday
            end: Date("2025-01-05T00:00:00-03:00")   // Next Sunday
        )

        // WHEN - Navigate with week component
        let next = calendar.navigate(interval, direction: .forward, component: .weekOfYear)
        let previous = calendar.navigate(interval, direction: .backward, component: .weekOfYear)

        // THEN
        #expect(next.start == Date("2025-01-05T00:00:00-03:00"))
        #expect(next.end == Date("2025-01-12T00:00:00-03:00"))

        #expect(previous.start == Date("2024-12-22T00:00:00-03:00"))
        #expect(previous.end == Date("2024-12-29T00:00:00-03:00"))
    }

    @Test("Navigate respects provided calendar parameter")
    func navigateRespectsCalendarParameter() {
        // GIVEN - Custom period that doesn't align with calendar boundaries
        let interval = DateInterval(
            start: Date("2025-01-10T12:00:00-03:00"),
            end: Date("2025-01-20T12:00:00-03:00")
        )

        // Different calendar with different week start
        var mondayCalendar = Calendar.mock(timeZone: .eastern)
        mondayCalendar.firstWeekday = 2 // Monday

        var sundayCalendar = Calendar.mock(timeZone: .eastern)
        sundayCalendar.firstWeekday = 1 // Sunday

        // WHEN - Navigate with different calendars using day component
        let nextWithMondayCalendar = mondayCalendar.navigate(interval, direction: .forward, component: .day)
        let nextWithSundayCalendar = sundayCalendar.navigate(interval, direction: .forward, component: .day)

        // THEN - Since we're using day component, both should navigate by 10 days
        #expect(nextWithMondayCalendar.start == Date("2025-01-20T12:00:00-03:00"))
        #expect(nextWithMondayCalendar.end == Date("2025-01-30T12:00:00-03:00"))

        #expect(nextWithSundayCalendar.start == Date("2025-01-20T12:00:00-03:00"))
        #expect(nextWithSundayCalendar.end == Date("2025-01-30T12:00:00-03:00"))
    }

    // MARK: - Determine Navigation Component Tests

    @Test("Determine navigation component for single day")
    func determineNavigationComponentSingleDay() {
        // GIVEN
        let interval = DateInterval(
            start: Date("2025-01-15T00:00:00-03:00"),
            end: Date("2025-01-16T00:00:00-03:00")
        )

        // WHEN
        let component = calendar.determineNavigationComponent(for: interval)

        // THEN
        #expect(component == .day)
    }

    @Test("Determine navigation component for complete month", arguments: [
        (Date("2025-01-01T00:00:00-03:00"), Date("2025-02-01T00:00:00-03:00")),  // January
        (Date("2025-02-01T00:00:00-03:00"), Date("2025-03-01T00:00:00-03:00")),  // February (non-leap)
        (Date("2024-02-01T00:00:00-03:00"), Date("2024-03-01T00:00:00-03:00")),  // February (leap)
        (Date("2025-04-01T00:00:00-03:00"), Date("2025-05-01T00:00:00-03:00")),  // April (30 days)
        (Date("2025-12-01T00:00:00-03:00"), Date("2026-01-01T00:00:00-03:00"))   // December
    ])
    func determineNavigationComponentMonth(startDate: Date, endDate: Date) {
        // GIVEN
        let interval = DateInterval(start: startDate, end: endDate)

        // WHEN
        let component = calendar.determineNavigationComponent(for: interval)

        // THEN
        #expect(component == .month)
    }

    @Test("Determine navigation component for complete year", arguments: [
        (Date("2025-01-01T00:00:00-03:00"), Date("2026-01-01T00:00:00-03:00")),  // Regular year
        (Date("2024-01-01T00:00:00-03:00"), Date("2025-01-01T00:00:00-03:00")),  // Leap year
        (Date("2023-01-01T00:00:00-03:00"), Date("2024-01-01T00:00:00-03:00"))   // Year before leap
    ])
    func determineNavigationComponentYear(startDate: Date, endDate: Date) {
        // GIVEN
        let interval = DateInterval(start: startDate, end: endDate)

        // WHEN
        let component = calendar.determineNavigationComponent(for: interval)

        // THEN
        #expect(component == .year)
    }

    @Test("Determine navigation component for complete week")
    func determineNavigationComponentWeek() {
        // GIVEN - Full week (Sunday to Sunday in eastern calendar)
        let interval = DateInterval(
            start: Date("2025-01-12T00:00:00-03:00"),  // Sunday
            end: Date("2025-01-19T00:00:00-03:00")     // Next Sunday
        )

        // WHEN
        let component = calendar.determineNavigationComponent(for: interval)

        // THEN
        #expect(component == .weekOfYear)
    }

    @Test("Determine navigation component for week at year boundary")
    func determineNavigationComponentWeekYearBoundary() {
        // GIVEN - Week that crosses year boundary
        let interval = DateInterval(
            start: Date("2024-12-29T00:00:00-03:00"),  // Sunday
            end: Date("2025-01-05T00:00:00-03:00")     // Next Sunday
        )

        // WHEN
        let component = calendar.determineNavigationComponent(for: interval)

        // THEN
        #expect(component == .weekOfYear)
    }

    @Test("Determine navigation component for custom periods returns nil", arguments: [
        // 3 days
        (Date("2025-01-10T00:00:00-03:00"), Date("2025-01-13T00:00:00-03:00")),
        // 10 days
        (Date("2025-01-10T00:00:00-03:00"), Date("2025-01-20T00:00:00-03:00")),
        // 15 days (partial month)
        (Date("2025-01-10T00:00:00-03:00"), Date("2025-01-25T00:00:00-03:00")),
        // 5 days (partial week)
        (Date("2025-01-13T00:00:00-03:00"), Date("2025-01-18T00:00:00-03:00")),
        // Partial month starting mid-month
        (Date("2025-01-15T00:00:00-03:00"), Date("2025-02-15T00:00:00-03:00")),
        // 6 months (half year)
        (Date("2025-01-01T00:00:00-03:00"), Date("2025-07-01T00:00:00-03:00"))
    ])
    func determineNavigationComponentCustomPeriods(startDate: Date, endDate: Date) {
        // GIVEN
        let interval = DateInterval(start: startDate, end: endDate)

        // WHEN
        let component = calendar.determineNavigationComponent(for: interval)

        // THEN
        #expect(component == nil)
    }

    @Test("Determine navigation component with time offsets")
    func determineNavigationComponentTimeOffsets() {
        // GIVEN - Month interval with slight time offsets (within 1 second tolerance)
        let start = Date("2025-01-01T00:00:00-03:00").addingTimeInterval(0.5)  // 0.5 seconds offset
        let end = Date("2025-02-01T00:00:00-03:00").addingTimeInterval(0.5)
        let intervalWithOffset = DateInterval(start: start, end: end)

        // WHEN
        let component = calendar.determineNavigationComponent(for: intervalWithOffset)

        // THEN - Should still recognize as month
        #expect(component == .month)
    }

    @Test("Determine navigation component rejects intervals beyond tolerance")
    func determineNavigationComponentBeyondTolerance() {
        // GIVEN - Month interval with time offset beyond 1 second
        let intervalBeyondTolerance = DateInterval(
            start: Date("2025-01-01T00:00:02-03:00"),  // 2 seconds offset
            end: Date("2025-02-01T00:00:00-03:00")
        )

        // WHEN
        let component = calendar.determineNavigationComponent(for: intervalBeyondTolerance)

        // THEN - Should not recognize as month
        #expect(component == nil)
    }

    @Test("Determine navigation component for different calendar configurations")
    func determineNavigationComponentDifferentCalendars() {
        // GIVEN
        var mondayCalendar = Calendar.mock(timeZone: .eastern)
        mondayCalendar.firstWeekday = 2  // Monday

        // Week starting on Monday
        let mondayWeekInterval = DateInterval(
            start: Date("2025-01-13T00:00:00-03:00"),  // Monday
            end: Date("2025-01-20T00:00:00-03:00")     // Next Monday
        )

        // WHEN
        let component = mondayCalendar.determineNavigationComponent(for: mondayWeekInterval)

        // THEN
        #expect(component == .weekOfYear)
    }

    @Test("Determine navigation component edge cases")
    func determineNavigationComponentEdgeCases() {
        // GIVEN - Zero duration interval (same start and end)
        let zeroDuration = DateInterval(
            start: Date("2025-01-15T00:00:00-03:00"),
            end: Date("2025-01-15T00:00:00-03:00")
        )

        // Almost a day (23 hours 59 minutes 59 seconds)
        let almostDay = DateInterval(
            start: Date("2025-01-15T00:00:00-03:00"),
            end: Date("2025-01-15T23:59:59-03:00")
        )

        // WHEN/THEN
        #expect(calendar.determineNavigationComponent(for: zeroDuration) == nil)
        #expect(calendar.determineNavigationComponent(for: almostDay) == .day)
    }
}
