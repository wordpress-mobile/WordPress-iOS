import XCTest
@testable import WordPress

final class NotificationCommentRangeTests: XCTestCase {
    private let contextManager = TestContextManager()

    private var subject: NotificationCommentRange?

    private struct Constants {
        static let kind = FormattableRangeKind("comment")
        static let range = NSRange(location: 32, length: 41)
        static let userId = NSNumber(integerLiteral: 1)
        static let siteId = NSNumber(integerLiteral: 2)
        static let postId = NSNumber(integerLiteral: 3)
        static let commentId = NSNumber(integerLiteral: 4)
    }

    override func setUp() {
        super.setUp()
        subject = NotificationCommentRange(commentID: Constants.commentId, properties: mockProperties())
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func testKindIsNotMutated() {
        XCTAssertEqual(subject?.kind, Constants.kind)
    }

    func testRangeIsNotMutated() {
        XCTAssertEqual(subject?.range, Constants.range)
    }

    func testUserIDIsNotMutated() {
        XCTAssertEqual(subject?.userID, Constants.userId)
    }

    func testSiteIDIsNotMutated() {
        XCTAssertEqual(subject?.siteID, Constants.siteId)
    }

    func testPostIDIsNotMutated() {
        XCTAssertEqual(subject?.postID, Constants.postId)
    }

    func testCommentIDIsNotMutated() {
        XCTAssertEqual(subject?.commentID, Constants.commentId)
    }

    private func mockProperties() -> NotificationContentRange.Properties {
        var properties = NotificationContentRange.Properties(range: Constants.range)
        properties.userID = Constants.userId
        properties.siteID = Constants.siteId
        properties.postID = Constants.postId
        return properties
    }
}
