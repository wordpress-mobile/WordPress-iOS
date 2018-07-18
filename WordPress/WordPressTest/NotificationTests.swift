import Foundation
import XCTest
@testable import WordPress



/// Notifications Tests
///
class NotificationTests: XCTestCase {

    var contextManager: TestContextManager!

    override func setUp() {
        super.setUp()
        contextManager = TestContextManager()
    }

    override func tearDown() {
        // Note: We'll force TestContextManager override reset, since, for (unknown reasons) the TestContextManager
        // might be retained more than expected, and it may break other core data based tests.
        ContextManager.overrideSharedInstance(nil)
        super.tearDown()
    }

    func testBadgeNotificationHasBadgeFlagSetToTrue() {
        let note = loadBadgeNotification()
        XCTAssertTrue(note.isBadge)
    }

    func testBadgeNotificationHasRegularFieldsSet() {
        let note = loadBadgeNotification()
        XCTAssertNotNil(note.type)
        XCTAssertNotNil(note.noticon)
        XCTAssertNotNil(note.iconURL)
        XCTAssertNotNil(note.resourceURL)
        XCTAssertNotNil(note.timestampAsDate)
    }

    func testBadgeNotificationProperlyLoadsItsSubjectBlock() {
        let note = loadBadgeNotification()
        let subjectBlocks = note.subjectBlockGroup!
        XCTAssert(subjectBlocks.blocks.count == 1)

        let subjectBlock = note.subjectBlockGroup?.blocks.first!
        XCTAssertNotNil(subjectBlock)
        XCTAssertEqual(subjectBlock, note.subjectBlock!)
    }

    func testBadgeNotificationContainsOneImageBlockGroup() {
        let note = loadBadgeNotification()
        let group = note.blockGroupOfKind(.image)
        XCTAssertNotNil(group)

        let imageBlock = group!.blocks.first
        XCTAssertNotNil(imageBlock)

        let media = imageBlock!.media.first
        XCTAssertNotNil(media)
        XCTAssertNotNil(media!.mediaURL)
    }

    func testLikeNotificationReturnsTheProperKindValue() {
        let note = loadLikeNotification()
        XCTAssert(note.kind == .Like)
    }

    func testLikeNotificationContainsOneSubjectBlock() {
        let note = loadLikeNotification()
        XCTAssert(note.subjectBlockGroup!.blocks.count == 1)
        XCTAssertNotNil(note.subjectBlock)
        XCTAssertNotNil(note.subjectBlock!.text)
    }

    func testLikeNotificationContainsHeader() {
        let note = loadLikeNotification()
        let header = note.headerBlockGroup
        XCTAssertNotNil(header)

        let gravatarBlock = header!.blockOfKind(.image)
        XCTAssertNotNil(gravatarBlock!.text)

        let media = gravatarBlock!.media.first
        XCTAssertNotNil(media!.mediaURL)

        let snippetBlock = header!.blockOfKind(.text)
        XCTAssertNotNil(snippetBlock!.text)
    }

    func testLikeNotificationContainsUserBlocksInTheBody() {
        let note = loadLikeNotification()
        for group in note.bodyBlockGroups {
            XCTAssertTrue(group.kind == .user)
        }
    }

    func testLikeNotificationContainsPostAndSiteID() {
        let note = loadLikeNotification()
        XCTAssertNotNil(note.metaSiteID)
        XCTAssertNotNil(note.metaPostID)
    }

    func testFollowerNotificationReturnsTheProperKindValue() {
        let note = loadFollowerNotification()
        XCTAssert(note.kind == .Follow)
    }

    func testFollowerNotificationHasFollowFlagSetToTrue() {
        let note = loadFollowerNotification()
        XCTAssertTrue(note.kind == .Follow)
    }

    func testFollowerNotificationContainsOneSubjectBlock() {
        let note = loadFollowerNotification()
        XCTAssertNotNil(note.subjectBlock)
        XCTAssertNotNil(note.subjectBlock!.text)
    }

    func testFollowerNotificationContainsSiteID() {
        let note = loadFollowerNotification()
        XCTAssertNotNil(note.metaSiteID)
    }

    func testFollowerNotificationContainsUserAndFooterBlocksInTheBody() {
        let note = loadFollowerNotification()

        // Note: Account for 'View All Followers'
        for group in note.bodyBlockGroups {
            XCTAssertTrue(group.kind == .user || group.kind == .footer)
        }
    }

    func testFollowerNotificationContainsFooterBlockWithFollowRangeAtTheEnd() {
        let note = loadFollowerNotification()

        let lastGroup = note.bodyBlockGroups.last
        XCTAssertNotNil(lastGroup)
        XCTAssertTrue(lastGroup!.kind == .footer)

        let block = lastGroup!.blocks.first
        XCTAssertNotNil(block)
        XCTAssertNotNil(block!.text)
        XCTAssertNotNil(block!.ranges)

        let range = block!.ranges.first
        XCTAssertNotNil(range)
        XCTAssert(range!.kind == .Follow)
    }

    func testCommentNotificationReturnsTheProperKindValue() {
        let note = loadCommentNotification()
        XCTAssert(note.kind == .Comment)
    }

    func testCommentNotificationHasCommentFlagSetToTrue() {
        let note = loadCommentNotification()
        XCTAssertTrue(note.kind == .Comment)
    }

    func testCommentNotificationContainsSubjectWithSnippet() {
        let note = loadCommentNotification()

        XCTAssertNotNil(note.subjectBlock)
        XCTAssertNotNil(note.snippetBlock)
        XCTAssertNotNil(note.subjectBlock!.text)
        XCTAssertNotNil(note.snippetBlock!.text)
    }

    func testCommentNotificationContainsHeader() {
        let note = loadCommentNotification()

        let header = note.headerBlockGroup
        XCTAssertNotNil(header)

        let gravatarBlock = header!.blockOfKind(.image)
        XCTAssertNotNil(gravatarBlock)
        XCTAssertNotNil(gravatarBlock!.text)

        let media = gravatarBlock!.media.first
        XCTAssertNotNil(media)
        XCTAssertNotNil(media!.mediaURL)

        let snippetBlock = header!.blockOfKind(.text)
        XCTAssertNotNil(snippetBlock)
        XCTAssertNotNil(snippetBlock!.text)
    }

    func testCommentNotificationContainsCommentAndSiteID() {
        let note = loadCommentNotification()
        XCTAssertNotNil(note.metaSiteID)
        XCTAssertNotNil(note.metaCommentID)
    }

    func testCommentNotificationProperlyChecksIfItWasRepliedTo() {
        let note = loadCommentNotification()
        XCTAssert(note.isRepliedComment)
    }

    func testFindingNotificationRangeSearchingByReplyCommentID() {
        let note = loadCommentNotification()
        XCTAssertNotNil(note.metaReplyID)

        let textBlock = note.blockGroupOfKind(.footer)?.blockOfKind(.text)
        XCTAssertNotNil(textBlock)

        let replyID = note.metaReplyID
        XCTAssertNotNil(replyID)

        let replyRange = textBlock!.notificationRangeWithCommentId(replyID!)
        XCTAssertNotNil(replyRange)
    }

    func testFindingNotificationRangeSearchingByURL() {
        let note = loadBadgeNotification()
        let targetURL = URL(string: "http://www.wordpress.com")!
        let range = note.notificationRangeWithUrl(targetURL)

        XCTAssertNotNil(range)
    }


    // MARK: - Helpers

    var entityName: String {
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
}
