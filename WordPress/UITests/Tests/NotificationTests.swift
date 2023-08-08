import UITestsFoundation
import XCTest

private extension String {
    static let commentNotificationString = "commented on"
    static let followNotificationString = "followed your blog"
    static let likeNotificationString = "liked your post"

    static let comment = "Comment"
    static let follow = "Follow"
    static let like = "Like"
}

class NotificationTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        setUpTestSuite()

        try LoginFlow.login(email: WPUITestCredentials.testWPcomUserEmail)
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
        try super.tearDownWithError()
    }

    func testViewNotification() throws {
        try TabNavComponent()
            .goToNotificationsScreen()
            .assertScreenIsLoaded()
            .openNotification(withSubstring: .commentNotificationString)
            .verifyNotification(ofType: .comment)
            .openNotification(withSubstring: .followNotificationString)
            .verifyNotification(ofType: .follow)
            .openNotification(withSubstring: .likeNotificationString)
            .verifyNotification(ofType: .like)
    }
}
