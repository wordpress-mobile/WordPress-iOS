import XCTest
@testable import WordPress

final class NewsItemTests: XCTestCase {
    private struct Constants {
        static let message = "🦄"
    }

    private var subject: NewsItem?

    override func setUp() {
        super.setUp()
        subject = NewsItem(content: Constants.message)
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func testMessageMatchesExpectation() {
        XCTAssertEqual(subject?.content, Constants.message)
    }
}
