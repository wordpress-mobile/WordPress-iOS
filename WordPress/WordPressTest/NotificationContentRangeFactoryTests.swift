import XCTest
@testable import WordPress

final class NotificationContentRangeFactoryTests: XCTestCase {
    private let contextManager = TestContextManager()

    func testCommentRangeReturnsExpectedImplementationOfFormattableContentRange() {
        let subject = NotificationContentRangeFactory.contentRange(from: mockCommentRange()) as? FormattableCommentRange

        XCTAssertNotNil(subject)
    }

    func testIconRangeReturnsExpectedImplementationOfFormattableContentRange() {
        let subject = NotificationContentRangeFactory.contentRange(from: mockIconRange()) as? FormattableNoticonRange

        XCTAssertNotNil(subject)
    }

    func testPostRangeReturnsExpectedImplementationOfFormattableContentRange() {
        let subject = NotificationContentRangeFactory.contentRange(from: mockPostRange()) as? NotificationContentRange

        XCTAssertNotNil(subject)
    }

    func testSiteRangeReturnsExpectedImplementationOfFormattableContentRange() {
        let subject = NotificationContentRangeFactory.contentRange(from: mockSiteRange()) as? NotificationContentRange

        XCTAssertNotNil(subject)
    }

    func testUserRangeReturnsExpectedImplementationOfFormattableContentRange() {
        let subject = NotificationContentRangeFactory.contentRange(from: mockUserRange()) as? NotificationContentRange

        XCTAssertNotNil(subject)
    }

    func testDefaultRangeReturnsExpectedImplementationOfFormattableContentRange() {
        let subject = NotificationContentRangeFactory.contentRange(from: mockBlockQuoteRange()) as? NotificationContentRange

        XCTAssertNotNil(subject)
    }

    private func mockCommentRange() -> [String: AnyObject] {
        return getDictionaryFromFile(named: "notifications-comment-range.json")
    }

    private func mockIconRange() -> [String: AnyObject] {
        return getDictionaryFromFile(named: "notifications-icon-range.json")
    }

    private func mockPostRange() -> [String: AnyObject] {
        return getDictionaryFromFile(named: "notifications-post-range.json")
    }

    private func mockSiteRange() -> [String: AnyObject] {
        return getDictionaryFromFile(named: "notifications-site-range.json")
    }

    private func mockUserRange() -> [String: AnyObject] {
        return getDictionaryFromFile(named: "notifications-user-range.json")
    }

    private func mockBlockQuoteRange() -> [String: AnyObject] {
        return getDictionaryFromFile(named: "notifications-blockquote-range.json")
    }

    private func getDictionaryFromFile(named fileName: String) -> [String: AnyObject] {
        return contextManager.object(withContentOfFile: fileName) as! [String: AnyObject]
    }
}
