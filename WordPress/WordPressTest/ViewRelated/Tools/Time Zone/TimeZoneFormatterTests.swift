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
        // As of iOS 17.0, `DateFormatter` uses a narrow non-breaking space (U+202F) in output such as "7:00 PM".
        //
        // See:
        // - https://unicode-explorer.com/c/202F
        // - https://href.li/?https://developer.apple.com/forums/thread/731850
        //
        // An argument could be made to modify these tests, or the whole component, so that we don't need
        // to assert on what `DateFormatter` does for us. In the meantime, let's use the proper Unicode
        // character in the expectation.
        if #available(iOS 17.0, *) {
            XCTAssertEqual("6:00\u{202F}PM", timeAtZone)
        } else {
            XCTAssertEqual("6:00 PM", timeAtZone)
        }

        // When end of May date
        formatter = TimeZoneFormatter(currentDate: testEndOfMayDate)

        // Then TimeAtZone = "7:00 PM"
        timeAtZone = formatter.getTimeAtZone(timeZone)
        if #available(iOS 17.0, *) {
            XCTAssertEqual("7:00\u{202F}PM", timeAtZone)
        } else {
            XCTAssertEqual("7:00 PM", timeAtZone)
        }
    }
}
