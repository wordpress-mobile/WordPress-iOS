import XCTest
@testable import WordPress

final class NotificationContentRangeTests: XCTestCase {
    private let contextManager = TestContextManager()

    private var subject: NotificationContentRange?

    private struct Constants {
        static let kind = FormattableRangeKind("post")
        static let range = NSRange(location: 32, length: 41)
        static let userId = NSNumber(integerLiteral: 1)
        static let siteId = NSNumber(integerLiteral: 2)
        static let postId = NSNumber(integerLiteral: 3)
    }

    override func setUp() {
        super.setUp()
        subject = NotificationContentRange(kind: Constants.kind, properties: mockProperties())
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

    private func mockProperties() -> NotificationContentRange.Properties {
        var properties = NotificationContentRange.Properties(range: Constants.range)
        properties.userID = Constants.userId
        properties.siteID = Constants.siteId
        properties.postID = Constants.postId
        return properties
    }
}
