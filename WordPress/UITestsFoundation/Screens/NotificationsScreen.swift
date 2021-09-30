import XCTest

public class NotificationsScreen: BaseScreen {

    let replyButton: XCUIElement

    init() {
        let navBar = XCUIApplication().tables["Notifications Table"]
        replyButton = XCUIApplication().buttons["reply-button"]

        super.init(element: navBar)
    }

    public func openNotification(withText notificationText: String) -> NotificationsScreen {
        XCUIApplication().staticTexts[notificationText].tap()
        return self
    }

    @discardableResult
    public func replyToNotification() -> NotificationsScreen {
        replyButton.tap()
        return self
    }

    public static func isLoaded() -> Bool {
        return XCUIApplication().tables["Notifications Table"].exists
    }
}
