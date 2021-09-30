import XCTest
@testable import WordPress
@testable import WordPressKit

class TimeZoneFormatterTests: XCTestCase {

    // 2001-01-01 00:00:00 UTC
    let testWinterDate = Date(timeIntervalSinceReferenceDate: 0)

    // 2001-05-31 00:00:00 UTC
    let testSummerDate = Date(timeIntervalSinceReferenceDate: 12960000)

    let timeZone = NamedTimeZone(label: "Chicago", value: "America/Chicago")

    func testGetZoneOffset() throws {
        // Given TimeZoneFormatter
        // When TimeZone is Chicago
        // When winter date
        var formatter = TimeZoneFormatter(currentDate: testWinterDate)

        // Then zoneOffset = "Central Standard Time (GMT-06:00)"
        var zoneOffset = formatter.getZoneOffset(timeZone)
        XCTAssertEqual("Central Standard Time (GMT-06:00)", zoneOffset)

        // When summer date
        formatter = TimeZoneFormatter(currentDate: testSummerDate)

        // Then zoneOffset = "Central Standard Time (GMT-05:00)"
        zoneOffset = formatter.getZoneOffset(timeZone)
        XCTAssertEqual("Central Standard Time (GMT-05:00)", zoneOffset)
    }

    func testTimeAtZone() throws {
        // Given TimeZoneFormatter
        // When TimeZone is Chicago
        // When winter date
        var formatter = TimeZoneFormatter(currentDate: testWinterDate)

        // Then TimeAtZone = "6:00 PM"
        var timeAtZone = formatter.getTimeAtZone(timeZone)
        XCTAssertEqual("6:00 PM", timeAtZone)

        // When summer date
        formatter = TimeZoneFormatter(currentDate: testSummerDate)

        // Then TimeAtZone = "7:00 PM"
        timeAtZone = formatter.getTimeAtZone(timeZone)
        XCTAssertEqual("7:00 PM", timeAtZone)
    }
}
