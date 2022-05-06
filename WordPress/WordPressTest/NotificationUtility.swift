
import Foundation
import XCTest
@testable import WordPress

class NotificationUtility {
    var contextManager: TestContextManager!

    func setUp() {
        contextManager = TestContextManager()
    }

    func tearDown() {
        // Note: We'll force TestContextManager override reset, since, for (unknown reasons) the TestContextManager
        // might be retained more than expected, and it may break other core data based tests.
        contextManager.tearDown()
    }

    private var entityName: String {
        return Notification.classNameWithoutNamespaces()
    }

    func loadBadgeNotification() throws -> WordPress.Notification {
        return try .fixture(fromFile: "notifications-badge.json", insertInto: contextManager.mainContext)
    }

    func loadLikeNotification() throws -> WordPress.Notification {
        return try .fixture(fromFile: "notifications-like.json", insertInto: contextManager.mainContext)
    }

    func loadFollowerNotification() throws -> WordPress.Notification {
        return try .fixture(fromFile: "notifications-new-follower.json", insertInto: contextManager.mainContext)
    }

    func loadCommentNotification() throws -> WordPress.Notification {
        return try .fixture(fromFile: "notifications-replied-comment.json", insertInto: contextManager.mainContext)
    }

    func loadUnapprovedCommentNotification() throws -> WordPress.Notification {
        return try .fixture(fromFile: "notifications-unapproved-comment.json", insertInto: contextManager.mainContext)
    }

    func loadPingbackNotification() throws -> WordPress.Notification {
        return try .fixture(fromFile: "notifications-pingback.json", insertInto: contextManager.mainContext)
    }

    func mockCommentContent() throws -> FormattableCommentContent {
        let dictionary = try JSONObject.loadFile(named: "notifications-replied-comment.json")
        let body = dictionary["body"]
        let blocks = NotificationContentFactory.content(from: body as! [[String: AnyObject]], actionsParser: NotificationActionParser(), parent: WordPress.Notification(context: contextManager.mainContext))
        return blocks.filter { $0.kind == .comment }.first! as! FormattableCommentContent
    }

    func mockCommentContext() throws -> ActionContext<FormattableCommentContent> {
        return try ActionContext(block: mockCommentContent())
    }
}
