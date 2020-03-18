import XCTest
@testable import WordPress

class WeekdaysHeaderViewTests: XCTestCase {

    func testDisplayedWeekdaysMonday() {
        // A calendar with Monday as first weekday
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2

        let headerView = WeekdaysHeaderView(calendar: calendar)
        let firstWeekday = headerView.subviews.first as? UILabel
        let lastWeekday = headerView.subviews.last as? UILabel

        XCTAssertEqual(firstWeekday?.text, "M", "Label should show Monday as first weekday")
        XCTAssertEqual(lastWeekday?.text, "S", "Label should show Sunday as last weekday")
    }

    func testDisplayedWeekdaysSunday() {
        // A calendar with Monday as first weekday
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 1

        let headerView = WeekdaysHeaderView(calendar: calendar)
        let firstWeekday = headerView.subviews.first as? UILabel
        let lastWeekday = headerView.subviews.last as? UILabel

        XCTAssertEqual(firstWeekday?.text, "S", "Label should show Sunday as first weekday")
        XCTAssertEqual(lastWeekday?.text, "S", "Label should show Saturday as last weekday")
    }
}
