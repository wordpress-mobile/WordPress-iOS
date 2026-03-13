import Testing
import Foundation
@testable import JetpackStats

@Suite
struct StatsDateRangeSelectionTests {
    let calendar = Calendar.mock(timeZone: TimeZone(secondsFromGMT: 0)!)

    // MARK: - effectiveDateRange

    @Test
    func effectiveDateRangeReturnsRangeWhenNoSubrange() {
        let range = makeRange(start: "2025-01-01T00:00:00Z", end: "2025-01-08T00:00:00Z", component: .day)
        let selection = StatsDateRangeSelection(range: range)

        #expect(selection.effectiveDateRange == range)
    }

    @Test
    func effectiveDateRangeReturnsSubrangeWhenPresent() {
        let range = makeRange(start: "2025-01-01T00:00:00Z", end: "2025-01-08T00:00:00Z", component: .day)
        let subrange = makeRange(start: "2025-01-03T00:00:00Z", end: "2025-01-04T00:00:00Z", component: .day)
        let selection = StatsDateRangeSelection(range: range, subrange: subrange)

        #expect(selection.effectiveDateRange == subrange)
    }

    // MARK: - navigate (no subrange)

    @Test
    func navigateForwardWithNoSubrangeDelegatestoRange() {
        let range = makeRange(start: "2025-01-01T00:00:00Z", end: "2025-01-08T00:00:00Z", component: .weekOfYear)
        var selection = StatsDateRangeSelection(range: range)

        selection.navigate(.forward)

        #expect(selection.range.dateInterval.start == Date("2025-01-08T00:00:00Z"))
        #expect(selection.subrange == nil)
    }

    @Test
    func navigateBackwardWithNoSubrangeDelegatesToRange() {
        let range = makeRange(start: "2025-01-08T00:00:00Z", end: "2025-01-15T00:00:00Z", component: .weekOfYear)
        var selection = StatsDateRangeSelection(range: range)

        selection.navigate(.backward)

        #expect(selection.range.dateInterval.start == Date("2025-01-01T00:00:00Z"))
        #expect(selection.subrange == nil)
    }

    // MARK: - navigate (with subrange)

    @Test
    func navigateForwardWithSubrangeWithinRange() {
        let range = makeRange(start: "2025-01-01T00:00:00Z", end: "2025-01-08T00:00:00Z", component: .weekOfYear)
        let subrange = makeRange(start: "2025-01-03T00:00:00Z", end: "2025-01-04T00:00:00Z", component: .day)
        var selection = StatsDateRangeSelection(range: range, subrange: subrange)

        selection.navigate(.forward)

        // Subrange should move forward by one day, staying within range
        #expect(selection.subrange?.dateInterval.start == Date("2025-01-04T00:00:00Z"))
        #expect(selection.subrange?.dateInterval.end == Date("2025-01-05T00:00:00Z"))
        // Range should remain unchanged
        #expect(selection.range == range)
    }

    @Test
    func navigateBackwardWithSubrangeWithinRange() {
        let range = makeRange(start: "2025-01-01T00:00:00Z", end: "2025-01-08T00:00:00Z", component: .weekOfYear)
        let subrange = makeRange(start: "2025-01-03T00:00:00Z", end: "2025-01-04T00:00:00Z", component: .day)
        var selection = StatsDateRangeSelection(range: range, subrange: subrange)

        selection.navigate(.backward)

        #expect(selection.subrange?.dateInterval.start == Date("2025-01-02T00:00:00Z"))
        #expect(selection.subrange?.dateInterval.end == Date("2025-01-03T00:00:00Z"))
        #expect(selection.range == range)
    }

    @Test
    func navigateForwardWithSubrangeClearsWhenExitingRange() {
        let range = makeRange(start: "2025-01-01T00:00:00Z", end: "2025-01-08T00:00:00Z", component: .weekOfYear)
        // Subrange is at the last day of the range
        let subrange = makeRange(start: "2025-01-07T00:00:00Z", end: "2025-01-08T00:00:00Z", component: .day)
        var selection = StatsDateRangeSelection(range: range, subrange: subrange)

        selection.navigate(.forward)

        // Navigating forward would put subrange outside range, so subrange should be cleared
        #expect(selection.subrange == nil)
        // Range should remain unchanged
        #expect(selection.range == range)
    }

    @Test
    func navigateBackwardWithSubrangeClearsWhenExitingRange() {
        let range = makeRange(start: "2025-01-01T00:00:00Z", end: "2025-01-08T00:00:00Z", component: .weekOfYear)
        // Subrange is at the first day of the range
        let subrange = makeRange(start: "2025-01-01T00:00:00Z", end: "2025-01-02T00:00:00Z", component: .day)
        var selection = StatsDateRangeSelection(range: range, subrange: subrange)

        selection.navigate(.backward)

        // Navigating backward would put subrange before range start, so subrange should be cleared
        #expect(selection.subrange == nil)
        #expect(selection.range == range)
    }

    // MARK: - canNavigate

    @Test
    func canNavigateReturnsTrueWhenSubrangeExists() {
        let range = makeRange(start: "2025-01-01T00:00:00Z", end: "2025-01-08T00:00:00Z", component: .weekOfYear)
        let subrange = makeRange(start: "2025-01-03T00:00:00Z", end: "2025-01-04T00:00:00Z", component: .day)
        let selection = StatsDateRangeSelection(range: range, subrange: subrange)

        #expect(selection.canNavigate(in: .forward))
        #expect(selection.canNavigate(in: .backward))
    }

    @Test
    func canNavigateDelegatesToRangeWhenNoSubrange() {
        // Range ends in the future, so can't navigate forward
        let range = StatsDateRange(
            interval: DateInterval(
                start: Date("2028-01-01T00:00:00Z"),
                end: Date("2028-01-08T00:00:00Z")
            ),
            component: .weekOfYear,
            calendar: calendar
        )
        let selection = StatsDateRangeSelection(range: range)

        #expect(!selection.canNavigate(in: .forward))
        #expect(selection.canNavigate(in: .backward))
    }

    // MARK: - Helpers

    private func makeRange(start: String, end: String, component: Calendar.Component) -> StatsDateRange {
        StatsDateRange(
            interval: DateInterval(start: Date(start), end: Date(end)),
            component: component,
            calendar: calendar
        )
    }
}
