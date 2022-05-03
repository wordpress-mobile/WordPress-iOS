import XCTest
@testable import WordPress

final class NotificationsContentFactoryTests: XCTestCase {
    private let contextManager = TestContextManager()
    private let entityName = Notification.classNameWithoutNamespaces()

    func testTextNotificationReturnsExpectedImplementationOfFormattableContent() throws {
        let subject = try NotificationContentFactory.content(from: [mockTextContentDictionary()], actionsParser: NotificationActionParser(), parent: loadLikeNotification()).first as? NotificationTextContent

        XCTAssertNotNil(subject)
    }

    func testCommentNotificationReturnsExpectedImplementationOfFormattableContent() throws {
        let subject = try NotificationContentFactory.content(from: [mockCommentContentDictionary()], actionsParser: NotificationActionParser(), parent: loadLikeNotification()).first as? FormattableCommentContent

        XCTAssertNotNil(subject)
    }

    func testUserNotificationReturnsExpectedImplementationOfFormattableContent() throws {
        let subject = try NotificationContentFactory.content(from: [mockUserContentDictionary()], actionsParser: NotificationActionParser(), parent: loadLikeNotification()).first as? FormattableUserContent

        XCTAssertNotNil(subject)
    }

    private func mockTextContentDictionary() throws -> [String: AnyObject] {
        return try getDictionaryFromFile(named: "notifications-text-content.json")
    }

    private func mockCommentContentDictionary() throws -> [String: AnyObject] {
        return try getDictionaryFromFile(named: "notifications-comment-content.json")
    }

    private func mockUserContentDictionary() throws -> [String: AnyObject] {
        return try getDictionaryFromFile(named: "notifications-user-content.json")
    }

    private func getDictionaryFromFile(named fileName: String) throws -> [String: AnyObject] {
        return try JSONObject.loadFile(named: fileName)
    }

    func loadLikeNotification() throws -> WordPress.Notification {
        return try .fixture(fromFile: "notifications-like.json", insertInto: contextManager.mainContext)
    }
}
