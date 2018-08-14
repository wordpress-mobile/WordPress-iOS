import XCTest
@testable import WordPress

final class NewsItemTests: XCTestCase {
    private struct Constants {
        static let title = "🦄"
        static let content = "🦄"
        static let infoURL = URL(string: "https://wordpress.com")!
    }

    private var subject: NewsItem?

    override func setUp() {
        super.setUp()
        subject = NewsItem(title: Constants.title, content: Constants.content, extendedInfoURL: Constants.infoURL)
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func testTitleMatchesExpectation() {
        XCTAssertEqual(subject?.title, Constants.title)
    }

    func testContentMatchesExpectation() {
        XCTAssertEqual(subject?.content, Constants.content)
    }

    func testURLMatchesExpectation() {
        XCTAssertEqual(subject?.extendedInfoURL, Constants.infoURL)
    }
}
