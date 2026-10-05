import XCTest

/// The details of one notification.
final class NotificationDetailsScreen: ScreenObject {
    /// - Parameter title: What the notification is about, which titles the screen: "6 Likes",
    ///   "Comment", "5 Followers".
    init(title: String, app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [{ $0.navigationBars[title] }], app: app)
    }

    /// Steps to the newer notification, the one above this one in the list.
    func goToNextNotification(titled title: String) throws -> NotificationDetailsScreen {
        try tap(app.buttons["Next notification"])
        return try NotificationDetailsScreen(title: title, app: app)
    }

    /// Steps to the older notification, the one below this one in the list.
    func goToPreviousNotification(titled title: String) throws -> NotificationDetailsScreen {
        try tap(app.buttons["Previous notification"])
        return try NotificationDetailsScreen(title: title, app: app)
    }
}
