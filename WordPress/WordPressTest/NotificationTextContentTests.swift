import XCTest
@testable import WordPress

final class NotificationTextContentTests: XCTestCase {
    private let contextManager = TestContextManager()
    private let entityName = Notification.classNameWithoutNamespaces()

    private var subject: NotificationTextContent?

    private struct Expectations {
        static let text = "Jennifer Parks and 658 others liked your post Bookmark Posts with Save For Later"
    }

    override func setUp() {
        super.setUp()
        subject = NotificationTextContent(dictionary: mockDictionary(), actions: [], ranges: [], parent: loadLikeNotification())
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func testKindReturnsExpectation() {
        let notificationKind = subject?.kind

        XCTAssertEqual(notificationKind, .text)
    }

    func testStringReturnsExpectation() {
        let value = subject?.text

        XCTAssertEqual(value, Expectations.text)
    }

    func testRangesAreEmpty() {
        let value = subject?.ranges

        XCTAssertEqual(value?.count, 0)
    }

    func testActionsAreEmpty() {
        let value = subject?.actions

        XCTAssertEqual(value?.count, 0)
    }

    private func mockDictionary() -> [String: AnyObject] {
        return getDictionaryFromFile(named: "notifications-text-content.json")
    }

    private func getDictionaryFromFile(named fileName: String) -> [String: AnyObject] {
        return contextManager.object(withContentOfFile: fileName) as! [String: AnyObject]
    }

    func loadLikeNotification() -> WordPress.Notification {
        return contextManager.loadEntityNamed(entityName, withContentsOfFile: "notifications-like.json") as! WordPress.Notification
    }
}
