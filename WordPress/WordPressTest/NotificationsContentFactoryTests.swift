import XCTest
@testable import WordPress

final class NotificationsContentFactoryTests: XCTestCase {
    private let contextManager = TestContextManager()
    private let entityName = Notification.classNameWithoutNamespaces()

    func testTextNotificationReturnsProperImplementationOfFormattableContent() {
        let subject = NotificationContentFactory.content(from: [mockDictionary()], actionsParser: NotificationActionParser(), parent: loadLikeNotification()).first as? NotificationTextContent

        XCTAssertNotNil(subject)
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
