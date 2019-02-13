import Foundation
import XCTest

class MySiteScreen: BaseScreen {
    let tabBar: TabNavComponent

    init() {
        let blogTable = XCUIApplication().tables["Blog Details Table"]
        tabBar = TabNavComponent()

        super.init(element: blogTable)
    }

    func dismissNotificationAlertIfNeeded() -> MySiteScreen {
        let notificationAlert = FancyAlertComponent()
        if notificationAlert.isLoaded() {
            notificationAlert.cancelAlert()
        }
        return self
    }

    func switchSite() -> MySitesScreen {
        app.buttons["Switch Site"].tap()

        return MySitesScreen()
    }
}
