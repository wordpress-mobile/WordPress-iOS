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
    func navigateForwardWithSubrangeAtEdgeMovesToFirstPeriodInNextRange() {
        let range = makeRange(start: "2025-01-01T00:00:00Z", end: "2025-01-08T00:00:00Z", component: .weekOfYear)
        // Subrange is at the last day of the range
        let subrange = makeRange(start: "2025-01-07T00:00:00Z", end: "2025-01-08T00:00:00Z", component: .day)
        var selection = StatsDateRangeSelection(range: range, subrange: subrange)

        selection.navigate(.forward)

        // Range navigates forward; subrange moves to the first day of the new range
        #expect(selection.range.dateInterval.start == Date("2025-01-08T00:00:00Z"))
        #expect(selection.subrange?.dateInterval.start == Date("2025-01-08T00:00:00Z"))
        #expect(selection.subrange?.dateInterval.end == Date("2025-01-09T00:00:00Z"))
    }

    @Test
    func navigateBackwardWithSubrangeAtEdgeMovesToLastPeriodInPreviousRange() {
        let range = makeRange(start: "2025-01-08T00:00:00Z", end: "2025-01-15T00:00:00Z", component: .weekOfYear)
        // Subrange is at the first day of the range
        let subrange = makeRange(start: "2025-01-08T00:00:00Z", end: "2025-01-09T00:00:00Z", component: .day)
        var selection = StatsDateRangeSelection(range: range, subrange: subrange)

        selection.navigate(.backward)

        // Range navigates backward; subrange moves to the last day of the new range
        #expect(selection.range.dateInterval.start == Date("2025-01-01T00:00:00Z"))
        #expect(selection.subrange?.dateInterval.start == Date("2025-01-07T00:00:00Z"))
        #expect(selection.subrange?.dateInterval.end == Date("2025-01-08T00:00:00Z"))
    }

    @Test
    func navigateWithLargeGranularitySubrange() {
        // Simulates custom weekly granularity in a 7-day range
        let range = makeRange(start: "2025-01-01T00:00:00Z", end: "2025-01-08T00:00:00Z", component: .weekOfYear)
        // Weekly subrange covers almost the entire range
        let subrange = makeRange(start: "2025-01-01T00:00:00Z", end: "2025-01-08T00:00:00Z", component: .weekOfYear)
        var selection = StatsDateRangeSelection(range: range, subrange: subrange)

        // Both directions should be navigable (falls through to range navigation)
        #expect(selection.canNavigate(in: .forward))
        #expect(selection.canNavigate(in: .backward))

        // Navigate forward: clears subrange and navigates the range
        selection.navigate(.forward)
        #expect(selection.subrange == nil)
        #expect(selection.range.dateInterval.start == Date("2025-01-08T00:00:00Z"))
    }

    // MARK: - canNavigate

    @Test
    func canNavigateReturnsTrueWhenSubrangeCanMoveWithinRange() {
        let range = makeRange(start: "2025-01-01T00:00:00Z", end: "2025-01-08T00:00:00Z", component: .weekOfYear)
        let subrange = makeRange(start: "2025-01-03T00:00:00Z", end: "2025-01-04T00:00:00Z", component: .day)
        let selection = StatsDateRangeSelection(range: range, subrange: subrange)

        #expect(selection.canNavigate(in: .forward))
        #expect(selection.canNavigate(in: .backward))
    }

    @Test
    func canNavigateReturnsTrueWhenSubrangeAtEdgeButRangeCanNavigate() {
        // Subrange at the end of the range — can't move forward within range,
        // but the range itself can navigate, so forward should still be enabled
        let range = makeRange(start: "2025-01-01T00:00:00Z", end: "2025-01-08T00:00:00Z", component: .weekOfYear)
        let subrange = makeRange(start: "2025-01-07T00:00:00Z", end: "2025-01-08T00:00:00Z", component: .day)
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
