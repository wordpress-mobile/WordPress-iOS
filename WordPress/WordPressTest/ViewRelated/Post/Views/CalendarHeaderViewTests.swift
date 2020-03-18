import XCTest
@testable import WordPress

class CalendarHeaderViewTests: XCTestCase {

    func testDisplayedMonths() {
        let gmtTimeZone = TimeZone(secondsFromGMT: 0)
        var calendar = Calendar.current
        calendar.timeZone = gmtTimeZone!

        let dateComponents = DateComponents(calendar: calendar, timeZone: gmtTimeZone, year: 2020, month: 3, day: 1, hour: 0, minute: 0)

        let headerView = CalendarHeaderView(calendar: calendar, next: (self, #selector(selectorForTest)), previous: (self, #selector(selectorForTest)))
        if let date = dateComponents.date {
            headerView.set(date: date)
        }

        XCTAssertEqual(headerView.titleLabel.text, "March, 2020", "Label should show appropriate month and year")
    }

    func selectorForTest() {

    }
}
