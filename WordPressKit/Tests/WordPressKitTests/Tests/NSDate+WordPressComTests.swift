@testable import WordPressKit
import XCTest

class NSDateWordPressComTests: XCTestCase {

    func testValidRFC3339DateFromString() {
        XCTAssertEqual(
            NSDate.with(wordPressComJSONString: "2023-03-19T15:00:00Z"),
            Date(timeIntervalSince1970: 1_679_238_000)
        )
    }

    func testInvalidRFC3339DateFromString() {
        XCTAssertNil(NSDate.with(wordPressComJSONString: "2024-01-01"))
    }

    func testInvalidDateFromString() {
        XCTAssertNil(NSDate.with(wordPressComJSONString: "not a date"))
    }

    func testValidRFC3339StringFromDate() {
        XCTAssertEqual(
            NSDate(timeIntervalSince1970: 1_679_238_000).wordPressComJSONString(),
            // Apparently, NSDateFormatter doesn't offer a way to specify Z vs +0000.
            // This might go all the way back to the ISO 8601 and RFC 3339 specs overlap.
            "2023-03-19T15:00:00+0000"
        )
    }
}
