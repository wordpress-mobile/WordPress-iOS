import Foundation
import XCTest

class NotificationsScreen: BaseScreen {

    private struct ElementStringIDs {
        static let notificationDismissButton = "no-button"
    }

    let tabBar: TabNavComponent

    init() {
        let navBar = XCUIApplication().tables["Notifications Table"]
        tabBar = TabNavComponent()

        super.init(element: navBar)
    }

    @discardableResult
    func dismissNotificationMessageIfNeeded() -> NotificationsScreen {
        //Tap the "Not Now" button to dismiss the notifications prompt
        let notNowButton = app.buttons[ElementStringIDs.notificationDismissButton]

        if notNowButton.exists {
            notNowButton.tap()
        }

        return self
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().tables["Notifications Table"].exists
    }
}
