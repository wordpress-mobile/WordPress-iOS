import XCTest

/// The Notifications tab.
final class NotificationsScreen: ScreenObject {
    enum Filter: String, CaseIterable {
        case unread
        case comments = "comment"
        case subscribers = "follow"
        case likes = "like"
        case all = "none"
    }

    private let tableGetter: ElementGetter = {
        $0.tables["notifications-table"]
    }

    var table: XCUIElement { tableGetter(app) }

    /// The notifications listed under the selected filter.
    var notifications: XCUIElementQuery { table.cells }

    init(app: XCUIApplication) throws {
        Self.declinePushNotifications(in: app, coveringListWith: tableGetter(app))
        try super.init(expectedElementGetters: [tableGetter], app: app)
    }

    @discardableResult
    func select(_ filter: Filter) throws -> Self {
        try select(tab: app.buttons[filter.rawValue])
        return self
    }

    /// The notification whose text starts with `prefix`.
    func notification(beginningWith prefix: String) -> XCUIElement {
        table.cells.containing(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
    }

    /// Opens a notification. Its details are titled with what it's about, such as "6 Likes".
    func goToNotification(beginningWith prefix: String, titled title: String) throws -> NotificationDetailsScreen {
        let row = notification(beginningWith: prefix)
        try scroll(to: row, in: table)
        row.tap()
        return try NotificationDetailsScreen(title: title, app: app)
    }

    func openMenu() throws -> MenuComponent {
        try tap(app.navigationBars["Notifications"].buttons["Navigation Bar Menu Button"])
        return try MenuComponent(expecting: "Notification Settings", app: app)
    }

    func goToNotificationSettings() throws -> SheetScreen {
        try openMenu().select("Notification Settings")
        return try SheetScreen(title: "Notification Settings", dismissButton: "Done", app: app)
    }

    /// The first time the tab is shown the app asks to send push notifications, in a sheet that
    /// covers the list. Declining leaves the system's own permission prompt unasked.
    private static func declinePushNotifications(in app: XCUIApplication, coveringListWith table: XCUIElement) {
        // The list's header has a hidden copy of the button, which is the one with an identifier.
        let notNow = app.buttons.matching(NSPredicate(format: "label == 'Not now' AND identifier == ''")).firstMatch
        let deadline = Date(timeIntervalSinceNow: defaultWaitTimeout)

        while !table.isHittable, Date() < deadline {
            if notNow.exists {
                notNow.tap()
            }
        }
    }
}
