import Foundation
import XCTest

@testable import WordPress

class PostListHelperTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testDateAndTimeFormatter() {
        let date = Date.init(timeIntervalSince1970: 10)
        let expectedDateString = "Dec 31, 1969 @ 7:00 PM"

        let sut = PostListHelper.dateAndTime(for: date)

        XCTAssertEqual(expectedDateString, sut, "The dates should be in 'MMM dd, yyyy @ HH:mm a' format.")
    }
}
