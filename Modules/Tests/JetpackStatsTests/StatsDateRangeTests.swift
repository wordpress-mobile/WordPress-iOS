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
}
