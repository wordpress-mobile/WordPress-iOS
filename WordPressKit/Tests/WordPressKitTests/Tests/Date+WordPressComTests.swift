@testable import WordPressKit
import XCTest

// This is an incomplete test for implementing RFC 3339.
// It's purpose is to ensure our code "works".
//
// See also:
//
// - https://developer.wordpress.com/docs/api/
// - https://datatracker.ietf.org/doc/html/rfc3339
class DateWordPressComTests: XCTestCase {

    func testValidRFC3339DateFromString() {
        XCTAssertEqual(
            Date.with(wordPressComJSONString: "2023-03-19T15:00:00Z"),
            Date(timeIntervalSince1970: 1_679_238_000)
        )
    }

    func testInvalidRFC3339DateFromString() {
        XCTAssertNil(Date.with(wordPressComJSONString: "2024-01-01"))
    }

    func testInvalidDateFromString() {
        XCTAssertNil(Date.with(wordPressComJSONString: "not a date"))
    }

    func testValidRFC3339StringFromDate() {
        XCTAssertEqual(
            Date(timeIntervalSince1970: 1_679_238_000).wordPressComJSONString,
            // Apparently, NSDateFormatter doesn't offer a way to specify Z vs +0000.
            // This might go all the way back to the ISO 8601 and RFC 3339 specs overlap.
            "2023-03-19T15:00:00+0000"
        )
    }
}
