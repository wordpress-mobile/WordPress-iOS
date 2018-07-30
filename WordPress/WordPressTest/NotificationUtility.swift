
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
        ContextManager.overrideSharedInstance(nil)
    }

    private var entityName: String {
        return Notification.classNameWithoutNamespaces()
    }

    func loadBadgeNotification() -> WordPress.Notification {
        return contextManager.loadEntityNamed(entityName, withContentsOfFile: "notifications-badge.json") as! WordPress.Notification
    }

    func loadLikeNotification() -> WordPress.Notification {
        return contextManager.loadEntityNamed(entityName, withContentsOfFile: "notifications-like.json") as! WordPress.Notification
    }

    func loadFollowerNotification() -> WordPress.Notification {
        return contextManager.loadEntityNamed(entityName, withContentsOfFile: "notifications-new-follower.json") as! WordPress.Notification
    }

    func loadCommentNotification() -> WordPress.Notification {
        return contextManager.loadEntityNamed(entityName, withContentsOfFile: "notifications-replied-comment.json") as! WordPress.Notification
    }

    func loadUnapprovedCommentNotification() -> WordPress.Notification {
        return contextManager.loadEntityNamed(entityName, withContentsOfFile: "notifications-unapproved-comment.json") as! WordPress.Notification
    }

    func loadPingbackNotification() -> WordPress.Notification {
        return contextManager.loadEntityNamed(entityName, withContentsOfFile: "notifications-pingback.json") as! WordPress.Notification
    }

    func mockCommentContent() -> FormattableCommentContent {
        let dictionary = contextManager.object(withContentOfFile: "notifications-replied-comment.json") as! [String: AnyObject]
        let body = dictionary["body"]
        let blocks = NotificationContentFactory.content(from: body as! [[String : AnyObject]], actionsParser: NotificationActionParser(), parent: WordPress.Notification(context: contextManager.mainContext))
        return blocks.filter{ $0.kind == .comment }.first! as! FormattableCommentContent
    }

    func mockCommentContext() -> ActionContext<FormattableCommentContent> {
        return ActionContext(block: mockCommentContent())
    }
}
