import UITestsFoundation
import XCTest

private extension String {
    static let commentNotificationString = "commented on"
    static let followNotificationString = "followed your blog"
    static let likeNotificationString = "liked your post"
    static let commentText = "Reply to comment from app"

    static let comment = "Comment"
    static let follow = "Follow"
    static let like = "Like"
}

class NotificationTests: XCTestCase {

    @MainActor
    override func setUp() async throws {
        setUpTestSuite(selectWPComSite: WPUITestCredentials.testWPcomPaidSite)
        try await WireMock.setUpScenario(scenario: "comment_flow")
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
    }

    func testViewNotification() throws {
        try TabNavComponent()
            .goToNotificationsScreen()
            .openNotification(withSubstring: .commentNotificationString)
            .verifyNotification(ofType: .comment)
            .openNotification(withSubstring: .followNotificationString)
            .verifyNotification(ofType: .follow)
            .openNotification(withSubstring: .likeNotificationString)
            .verifyNotification(ofType: .like)
    }

    func testReplyNotification() throws {
        try TabNavComponent()
            .goToNotificationsScreen()
            .openNotification(withSubstring: .commentNotificationString)
            .replyToComment(withText: .commentText)
            .verifyReplySent()
    }

    func testLikeNotification() throws {
        // Get number of likes before liking the notification
        let (updatedNotificationsScreen, initialLikes) = try TabNavComponent()
            .goToNotificationsScreen()
            .openNotification(withSubstring: .commentNotificationString)
            .getNumberOfLikesForNotification()!

        // Tapping like and verify that like count increased
        updatedNotificationsScreen
            .likeComment()
            .verifyCommentLiked(expectedLikes: initialLikes + 1)
    }
}
