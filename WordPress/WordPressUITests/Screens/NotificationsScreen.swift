import UITestsFoundation
import XCTest

class NotificationsScreen: BaseScreen {

    let tabBar: TabNavComponent
    let replyButton: XCUIElement

    init() {
        let navBar = XCUIApplication().tables["Notifications Table"]
        replyButton = XCUIApplication().buttons["reply-button"]
        tabBar = TabNavComponent()

        super.init(element: navBar)
    }

    func openNotification(withText notificationText: String) -> NotificationsScreen {
        XCUIApplication().staticTexts[notificationText].tap()
        return self
    }

    @discardableResult
    func replyToNotification() -> NotificationsScreen {
        replyButton.tap()
        return self
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().tables["Notifications Table"].exists
    }
}
