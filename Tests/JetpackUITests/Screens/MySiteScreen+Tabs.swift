import XCTest

/// Navigation to the app's other tabs.
extension MySiteScreen {
    func goToReader() throws -> ReaderScreen {
        try tap(app.buttons["tabbar_reader"])
        return try ReaderScreen(app: app)
    }

    func goToNotifications() throws -> NotificationsScreen {
        try tap(app.buttons["tabbar_notifications"])
        return try NotificationsScreen(app: app)
    }

    func goToMe() throws -> MeScreen {
        try tap(app.buttons["tabbar_me"])
        return try MeScreen(app: app)
    }
}
