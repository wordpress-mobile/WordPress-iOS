import XCTest

/// Covers the Notifications tab: the list, its filters, each kind of notification and the menu.
///
/// Runs on the fixtures backend. Showing the tab marks the account's notifications as seen, and
/// opening one marks it as read, so against a real account these tests would change it. The
/// fixture account always has the same five notifications, which the tests assert on.
final class NotificationsTests: JetpackUITestCase {
    override class var backend: Backend { .fixtures }
    override class var resetsAppBeforeEachTest: Bool { false }

    private enum Fixture {
        static let likes = "Amechie Ajimobi and 5 others liked your post"
        static let comment = "Reyansh Pawar commented on"
        static let post = "Kate Williams posted on"
        static let followers = "Pamela Nguyen and 4 others followed your blog"
        static let achievement = "October 5: Your best day for likes"

        static let all = [likes, comment, post, followers, achievement]
    }

    private func notifications() throws -> NotificationsScreen {
        try MySiteScreen(app: app)
            .goToNotifications()
    }

    func testListShowsEveryNotification() throws {
        let notifications = try notifications()
            .select(.all)

        for text in Fixture.all {
            try notifications.waitFor(notifications.notification(beginningWith: text))
        }
    }

    func testFilters() throws {
        let notifications = try notifications()

        let expected: [(NotificationsScreen.Filter, [String])] = [
            (.unread, [Fixture.likes, Fixture.post, Fixture.followers]),
            (.comments, [Fixture.comment]),
            (.subscribers, [Fixture.followers]),
            (.likes, [Fixture.likes]),
            (.all, Fixture.all)
        ]
        for (filter, texts) in expected {
            try notifications.select(filter)
            try notifications.wait(until: "\(texts.count) notifications under \(filter)") {
                notifications.notifications.count == texts.count
            }
            for text in texts {
                XCTAssertTrue(notifications.notification(beginningWith: text).exists, "\(text) isn't under \(filter)")
            }
        }
    }

    func testLikesNotification() throws {
        try notifications()
            .goToNotification(beginningWith: Fixture.likes, titled: "6 Likes")
            .waitForScreen()
    }

    func testCommentNotification() throws {
        try notifications()
            .goToNotification(beginningWith: Fixture.comment, titled: "Comment")
            .waitForScreen()
    }

    func testFollowersNotification() throws {
        try notifications()
            .goToNotification(beginningWith: Fixture.followers, titled: "5 Followers")
            .waitForScreen()
    }

    func testAchievementNotification() throws {
        try notifications()
            .goToNotification(beginningWith: Fixture.achievement, titled: "5 Likes")
            .waitForScreen()
    }

    func testSteppingBetweenNotifications() throws {
        try notifications()
            .goToNotification(beginningWith: Fixture.likes, titled: "6 Likes")
            .goToPreviousNotification(titled: "Comment")
            .goToNextNotification(titled: "6 Likes")
            .waitForScreen()
    }

    func testMenu() throws {
        try notifications()
            .openMenu()
            .waitForItems(["Mark All As Read", "Notification Settings"])
    }
}
