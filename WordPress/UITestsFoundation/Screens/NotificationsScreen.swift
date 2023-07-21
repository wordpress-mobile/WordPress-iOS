import ScreenObject
import XCTest

public class NotificationsScreen: ScreenObject {

    private let notificationsTableGetter: (XCUIApplication) -> XCUIElement = {
        $0.tables["Notifications Table"]
    }

    private let replyButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["reply-button"]
    }

    var notificationsTable: XCUIElement { notificationsTableGetter(app) }
    var replyButton: XCUIElement { replyButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ notificationsTableGetter ],
            app: app
        )
    }

    @discardableResult
    public func openNotification(withText notificationText: String) -> NotificationsScreen {
        app.staticTexts[notificationText].tap()
        return self
    }

    @discardableResult
    public func replyToNotification() -> NotificationsScreen {
        replyButton.tap()
        return self
    }

    public static func isLoaded() -> Bool {
        (try? NotificationsScreen().isLoaded) ?? false
    }
}
