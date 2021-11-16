import ScreenObject
import XCTest

public class NotificationsScreen: ScreenObject {

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ { $0.tables["Notifications Table"] } ],
            app: app
        )
    }

    public func openNotification(withText notificationText: String) -> NotificationsScreen {
        app.staticTexts[notificationText].tap()
        return self
    }

    @discardableResult
    public func replyToNotification() -> NotificationsScreen {
        let replyButton = app.buttons["reply-button"]
        replyButton.tap()
        return self
    }

    public static func isLoaded() -> Bool {
        (try? NotificationsScreen().isLoaded) ?? false
    }
}
