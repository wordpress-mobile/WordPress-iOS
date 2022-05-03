import XCTest
@testable import WordPress

final class NotificationContentRangeFactoryTests: XCTestCase {
    private let contextManager = TestContextManager()

    func testCommentRangeReturnsExpectedImplementationOfFormattableContentRange() throws {
        let subject = NotificationContentRangeFactory.contentRange(from: try mockCommentRange()) as? NotificationCommentRange

        XCTAssertNotNil(subject)
    }

    func testIconRangeReturnsExpectedImplementationOfFormattableContentRange() throws {
        let subject = NotificationContentRangeFactory.contentRange(from: try mockIconRange()) as? FormattableNoticonRange

        XCTAssertNotNil(subject)
    }

    func testPostRangeReturnsExpectedImplementationOfFormattableContentRange() throws {
        let subject = NotificationContentRangeFactory.contentRange(from: try mockPostRange()) as? NotificationContentRange

        XCTAssertNotNil(subject)
    }

    func testSiteRangeReturnsExpectedImplementationOfFormattableContentRange() throws {
        let subject = NotificationContentRangeFactory.contentRange(from: try mockSiteRange()) as? NotificationContentRange

        XCTAssertNotNil(subject)
    }

    func testUserRangeReturnsExpectedImplementationOfFormattableContentRange() throws {
        let subject = NotificationContentRangeFactory.contentRange(from: try mockUserRange()) as? NotificationContentRange

        XCTAssertNotNil(subject)
    }

    func testDefaultRangeReturnsExpectedImplementationOfFormattableContentRange() throws {
        let subject = NotificationContentRangeFactory.contentRange(from: try mockBlockQuoteRange()) as? NotificationContentRange

        XCTAssertNotNil(subject)
    }

    private func mockCommentRange() throws -> [String: AnyObject] {
        return try getDictionaryFromFile(named: "notifications-comment-range.json")
    }

    private func mockIconRange() throws -> [String: AnyObject] {
        return try getDictionaryFromFile(named: "notifications-icon-range.json")
    }

    private func mockPostRange() throws -> [String: AnyObject] {
        return try getDictionaryFromFile(named: "notifications-post-range.json")
    }

    private func mockSiteRange() throws -> [String: AnyObject] {
        return try getDictionaryFromFile(named: "notifications-site-range.json")
    }

    private func mockUserRange() throws -> [String: AnyObject] {
        return try getDictionaryFromFile(named: "notifications-user-range.json")
    }

    private func mockBlockQuoteRange() throws -> [String: AnyObject] {
        return try getDictionaryFromFile(named: "notifications-blockquote-range.json")
    }

    private func getDictionaryFromFile(named fileName: String) throws -> [String: AnyObject] {
        return try JSONObject.loadFile(named: fileName)
    }
}
