import XCTest
@testable import WordPressKit

final class RFC339NoTimeDateFormatterTests: XCTestCase {
    func testDateFromString_DTS() {
        // Given we pass a time zone and date string that has a
        // daylight saving time shift happening
        let timeZone = TimeZone(identifier: "America/Asuncion")!
        let sut = RFC339NoTimeDateFormatter(currentTimeZone: timeZone)
        let ordinaryFormatter = ordinaryFormatter(currentTimeZone: timeZone)
        let dateString = "2023-10-01"

        // When we turn dateString to date
        // Then ordinary formatter fails to convert DST dateString to string
        XCTAssertNil(ordinaryFormatter.date(from: dateString))

        // and SUT formatter converts DST dateString to string
        XCTAssertNotNil(sut.date(from: dateString))
    }

    func testDateFromString() {
        // Given we pass an ordinary date
        let timeZone = TimeZone(identifier: "Europe/Vilnius")!
        let sut = RFC339NoTimeDateFormatter(currentTimeZone: timeZone)
        let ordinaryFormatter = ordinaryFormatter(currentTimeZone: timeZone)
        let dateString = "2024-01-03"

        // When we turn dateString to date
        // Then ordinary formatter and SUT formatter should return the same date
        XCTAssertEqual(
            sut.date(from: dateString),
            ordinaryFormatter.date(from: dateString)
        )
    }

    func testStringFromDate_DTS() {
        let timeZone = TimeZone(identifier: "America/Asuncion")!
        let sut = RFC339NoTimeDateFormatter(currentTimeZone: timeZone)
        let ordinaryFormatter = ordinaryFormatter(currentTimeZone: timeZone)

        let date = date(year: 2023, month: 10, day: 01, timeZone: timeZone)

        XCTAssertEqual(sut.string(from: date), "2023-10-01")
        XCTAssertEqual(ordinaryFormatter.string(from: date), "2023-10-01")
    }

    func testStringFromDate() {
        let timeZone = TimeZone(identifier: "Australia/Adelaide")!
        let sut = RFC339NoTimeDateFormatter(currentTimeZone: timeZone)

        let date1 = date(year: 2023, month: 02, day: 02, hour: 23, timeZone: timeZone)
        XCTAssertEqual(sut.string(from: date1), "2023-02-02")

        let date2 = date(year: 2023, month: 02, day: 02, hour: 01, timeZone: timeZone)
        XCTAssertEqual(sut.string(from: date2), "2023-02-02")
    }
}

extension RFC339NoTimeDateFormatterTests {
    private func ordinaryFormatter(currentTimeZone: TimeZone) -> DateFormatter {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = currentTimeZone
        return df
    }

    private func date(year: Int, month: Int, day: Int, hour: Int? = nil, timeZone: TimeZone) -> Date {
        let calendar = Calendar(identifier: .iso8601)
        let dateComponents = DateComponents(calendar: calendar, timeZone: timeZone, year: year, month: month, day: day, hour: hour)
        return dateComponents.date!
    }
}
