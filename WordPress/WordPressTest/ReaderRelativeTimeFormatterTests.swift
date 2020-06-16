@testable import WordPress
import XCTest

class ReaderRelativeTimeFormatterTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()

        calendar = Calendar.init(identifier: .gregorian)
    }
    override func tearDown() {
        calendar = nil
        super.tearDown()
    }

    func testSecondsAgo() {
        let formatter = ReaderRelativeTimeFormatter(calendar: calendar)
        let date = Date(timeIntervalSinceNow: -10)

        XCTAssertEqual(formatter.string(from: date), "1m")
    }

    func testWithinAnHour() {
        let formatter = ReaderRelativeTimeFormatter(calendar: calendar)
        let date = Date(timeIntervalSinceNow: -(3600 - 1))

        XCTAssertEqual(formatter.string(from: date), "59m")
    }

    func testWithin24Hours() {
        let formatter = ReaderRelativeTimeFormatter(calendar: calendar)
        let date = Date(timeIntervalSinceNow: -(86400 - 1))

        XCTAssertEqual(formatter.string(from: date), "23h")
    }

    func testPastWeek() {
        let formatter = ReaderRelativeTimeFormatter(calendar: calendar)
        let date = Date(timeIntervalSinceNow: -(86400 * 6))

        XCTAssertEqual(formatter.string(from: date), "6d")
    }

    func testOlderThanAWeek() {
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("MMM dd")

        let formatter = ReaderRelativeTimeFormatter(calendar: calendar)
        let date = Date(timeIntervalSinceNow: -(86400 * 14))

        XCTAssertEqual(formatter.string(from: date), dateFormatter.string(from: date))
    }

    func testNotThisYear() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none

        let formatter = ReaderRelativeTimeFormatter(calendar: calendar)

        guard let date = calendar.date(from: DateComponents(year: 2001, month: 01, day: 01)) else {
            XCTFail()
            return
        }

        XCTAssertEqual(formatter.string(from: date), dateFormatter.string(from: date))
    }

    func testFutureDate() {
        let formatter = ReaderRelativeTimeFormatter(calendar: calendar)
        let date = Date(timeIntervalSinceNow: 3600)

        XCTAssertEqual(formatter.string(from: date), "just now")
    }
}
