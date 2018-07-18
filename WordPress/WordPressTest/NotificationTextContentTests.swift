import XCTest
@testable import WordPress

final class NotificationTextContentTests: XCTestCase {
    private let contextManager = TestContextManager()
    private let entityName = Notification.classNameWithoutNamespaces()

    private var subject: NotificationTextContent?

    override func setUp() {
        super.setUp()
        subject = NotificationTextContent(dictionary: mockDictionary(), actions: [], ranges: [], parent: loadFollowerNotification())
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func testKindReturnsExpectation() {
        let notificationKind = subject?.kind

        XCTAssertEqual(notificationKind, .text)
    }

    private func mockDictionary() -> [String: AnyObject] {
        return getDictionaryFromFile(named: "notifications-text-content.json")
    }

    private func getDictionaryFromFile(named fileName: String) -> [String: AnyObject] {
        return contextManager.object(withContentOfFile: fileName) as! [String: AnyObject]
    }

    func loadFollowerNotification() -> WordPress.Notification {
        return contextManager.loadEntityNamed(entityName, withContentsOfFile: "notifications-new-follower.json") as! WordPress.Notification
    }
}
