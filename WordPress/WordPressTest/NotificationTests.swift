import Foundation
import XCTest
@testable import WordPress



/// Notifications Tests
///
class NotificationTests: XCTestCase {

    let utility = NotificationUtility()

    override func setUp() {
        super.setUp()
        utility.setUp()
    }

    override func tearDown() {
        utility.tearDown()
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

    func testBadgeNotificationProperlyLoadsItsSubjectContent() {
        let note = utility.loadBadgeNotification()

        XCTAssert(note.subjectContentGroup?.blocks.count == 1)
        XCTAssertNotNil(note.subjectContentGroup?.blocks.first)
        XCTAssertNotNil(note.renderSubject())
    }

    func testBadgeNotificationContainsOneImageContentGroup() {
        let note = utility.loadBadgeNotification()
        let group = note.contentGroup(ofKind: .image)
        XCTAssertNotNil(group)

        let imageBlock = group?.blocks.first as? FormattableMediaContent
        XCTAssertNotNil(imageBlock)

        let media = imageBlock?.media.first
        XCTAssertNotNil(media)
        XCTAssertNotNil(media?.mediaURL)
    }

    func testLikeNotificationReturnsTheProperKindValue() {
        let note = loadLikeNotification()
        XCTAssert(note.kind == .Like)
    }

    func testLikeNotificationContainsHeaderContent() {
        let note = loadLikeNotification()
        let header = note.headerContentGroup
        XCTAssertNotNil(header)

        let gravatarBlock: NotificationTextContent? = header?.blockOfKind(.image)
        XCTAssertNotNil(gravatarBlock?.text)

        let media = gravatarBlock?.media.first
        XCTAssertNotNil(media?.mediaURL)

        let snippetBlock: NotificationTextContent? = header?.blockOfKind(.text)
        XCTAssertNotNil(snippetBlock?.text)
    }


    func testLikeNotificationContainsUserContentGroupsInTheBody() {
        let note = utility.loadLikeNotification()
        for group in note.bodyContentGroups {
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

    func testFollowerNotificationContainsOneSubjectContent() {
        let note = loadFollowerNotification()

        let content = note.subjectContentGroup?.blocks.first
        XCTAssertNotNil(content)
        XCTAssertNotNil(content?.text)
    }

    func testFollowerNotificationContainsSiteID() {
        let note = loadFollowerNotification()
        XCTAssertNotNil(note.metaSiteID)
    }

    func testFollowerNotificationContainsUserAndFooterGroupsInTheBody() {
        let note = utility.loadFollowerNotification()

        // Note: Account for 'View All Followers'
        for group in note.bodyContentGroups {
            XCTAssertTrue(group.kind == .user || group.kind == .footer)
        }
    }

    func testFollowerNotificationContainsFooterContentWithFollowRangeAtTheEnd() {
        let note = loadFollowerNotification()

        let lastGroup = note.bodyContentGroups.last
        XCTAssertNotNil(lastGroup)
        XCTAssertTrue(lastGroup!.kind == .footer)

        let block = lastGroup?.blocks.first
        XCTAssertNotNil(block)
        XCTAssertNotNil(block?.text)
        XCTAssertNotNil(block?.ranges)

        let range = block?.ranges.last
        XCTAssertNotNil(range)
        XCTAssert(range?.kind == .follow)
    }

    func testCommentNotificationReturnsTheProperKindValue() {
        let note = loadCommentNotification()
        XCTAssert(note.kind == .Comment)
    }

    func testCommentNotificationHasCommentFlagSetToTrue() {
        let note = loadCommentNotification()
        XCTAssertTrue(note.kind == .Comment)
    }

    func testCommentNotificationRendersSubjectWithSnippet() {
        let note = loadCommentNotification()

        XCTAssertNotNil(note.renderSubject())
        XCTAssertNotNil(note.renderSnippet())
    }

    func testCommentNotificationContainsHeaderContent() {
        let note = loadCommentNotification()

        let header = note.headerContentGroup
        XCTAssertNotNil(header)

        let gravatarBlock: NotificationTextContent? = header?.blockOfKind(.image)
        XCTAssertNotNil(gravatarBlock)
        XCTAssertNotNil(gravatarBlock?.text)

        let media = gravatarBlock!.media.first
        XCTAssertNotNil(media)
        XCTAssertNotNil(media!.mediaURL)

        let snippetBlock: NotificationTextContent? = header?.blockOfKind(.text)
        XCTAssertNotNil(snippetBlock)
        XCTAssertNotNil(snippetBlock?.text)
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

    func testCommentNotificationIsUnapproved() {
        let note = utility.loadUnapprovedCommentNotification()
        XCTAssertTrue(note.isUnapprovedComment)
    }

    func testCommentNotificationIsApproved() {
        let note = utility.loadCommentNotification()
        XCTAssertFalse(note.isUnapprovedComment)
    }

    func testFindingContentRangeSearchingByReplyCommentID() {
        let note = loadCommentNotification()
        XCTAssertNotNil(note.metaReplyID)

        let textBlock: FormattableTextContent? = note.contentGroup(ofKind: .footer)?.blockOfKind(.text)
        XCTAssertNotNil(textBlock)

        let replyID = note.metaReplyID
        XCTAssertNotNil(replyID)

        XCTAssertTrue(textBlock is NotificationTextContent)
        let mediaBlock = textBlock as? NotificationTextContent
        let replyRange = mediaBlock?.formattableContentRangeWithCommentId(replyID!)

        XCTAssertNotNil(replyRange)
    }

    func testFindingContentRangeSearchingByURL() {
        let note = loadBadgeNotification()
        let targetURL = URL(string: "http://www.wordpress.com")!
        let range = note.contentRange(with: targetURL)

        XCTAssertNotNil(range)
    }

    func testPingbackNotificationIsPingback() {
        let notification = utility.loadPingbackNotification()
        XCTAssertTrue(notification.isPingback)
    }

    func testPingbackBodyContainsFooter() {
        let notification = utility.loadPingbackNotification()
        let footer = notification.bodyContentGroups.filter { $0.kind == .footer }
        XCTAssertEqual(footer.count, 1)
    }

    func testHeaderAndBodyContentGroups() {
        let note = utility.loadCommentNotification()
        let headerGroupsCount = note.headerContentGroup != nil ? 1 : 0
        let bodyGroupsCount = note.bodyContentGroups.count
        let totalGroupsCount = headerGroupsCount + bodyGroupsCount

        XCTAssertEqual(note.headerAndBodyContentGroups.count, totalGroupsCount)
    }



    // MARK: - Helpers

    func loadBadgeNotification() -> WordPress.Notification {
        return utility.loadBadgeNotification()
    }

    func loadLikeNotification() -> WordPress.Notification {
        return utility.loadLikeNotification()
    }

    func loadFollowerNotification() -> WordPress.Notification {
        return utility.loadFollowerNotification()
    }

    func loadCommentNotification() -> WordPress.Notification {
        return utility.loadCommentNotification()
    }
}
