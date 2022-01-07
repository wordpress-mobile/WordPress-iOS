import XCTest
@testable import WordPress
@testable import WordPressKit

class TimeZoneFormatterTests: XCTestCase {

    // 2001-01-01 00:00:00 UTC
    let testBeginningOfYearDate = Date(timeIntervalSinceReferenceDate: 0)

    // 2001-05-31 00:00:00 UTC
    let testEndOfMayDate = Date(timeIntervalSinceReferenceDate: 12960000)

    let timeZone = NamedTimeZone(label: "Chicago", value: "America/Chicago")

    func testGetZoneOffset() throws {
        // Given TimeZoneFormatter
        // When TimeZone is Chicago
        // When beginning of year date
        var formatter = TimeZoneFormatter(currentDate: testBeginningOfYearDate)

        // Then zoneOffset = "Central Standard Time (GMT-06:00)"
        var zoneOffset = formatter.getZoneOffset(timeZone)
        XCTAssertEqual("Central Standard Time (GMT-06:00)", zoneOffset)

        // When end of May date
        formatter = TimeZoneFormatter(currentDate: testEndOfMayDate)

        // Then zoneOffset = "Central Standard Time (GMT-05:00)"
        zoneOffset = formatter.getZoneOffset(timeZone)
        XCTAssertEqual("Central Standard Time (GMT-05:00)", zoneOffset)
    }

    func testTimeAtZone() throws {
        // Given TimeZoneFormatter
        // When TimeZone is Chicago
        // When beginning of year date
        var formatter = TimeZoneFormatter(currentDate: testBeginningOfYearDate)

        // Then TimeAtZone = "6:00 PM"
        var timeAtZone = formatter.getTimeAtZone(timeZone)
        XCTAssertEqual("6:00 PM", timeAtZone)

        // When end of May date
        formatter = TimeZoneFormatter(currentDate: testEndOfMayDate)

        // Then TimeAtZone = "7:00 PM"
        timeAtZone = formatter.getTimeAtZone(timeZone)
        XCTAssertEqual("7:00 PM", timeAtZone)
    }
}
