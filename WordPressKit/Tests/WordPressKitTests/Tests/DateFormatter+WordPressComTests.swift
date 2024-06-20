@testable import WordPressKit
import XCTest

class DateFormatterWordPressComTests: XCTestCase {

    func testDateFormatterConfiguration() throws {
        let rfc3339Formatter = try XCTUnwrap(DateFormatter.wordPressCom)

        XCTAssertEqual(rfc3339Formatter.timeZone, TimeZone(secondsFromGMT: 0))
        XCTAssertEqual(rfc3339Formatter.locale, Locale(identifier: "en_US_POSIX"))
        XCTAssertEqual(rfc3339Formatter.dateFormat, "yyyy'-'MM'-'dd'T'HH':'mm':'ssZ")
    }
}
