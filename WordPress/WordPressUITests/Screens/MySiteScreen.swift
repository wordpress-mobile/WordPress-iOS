import Foundation
import XCTest

class MySiteScreen: BaseScreen {
    let tabBar: TabNavComponent
    let removeSiteButton: XCUIElement
    let removeSiteSheet: XCUIElement
    let removeSiteAlert: XCUIElement

    init() {
        let app = XCUIApplication()
        let blogTable = app.tables["Blog Details Table"]
        tabBar = TabNavComponent()
        removeSiteButton = app.cells["BlogDetailsRemoveSiteCell"]
        removeSiteSheet = app.sheets.buttons["Remove Site"]
        removeSiteAlert = app.alerts.buttons["Remove Site"]

        super.init(element: blogTable)
    }

    func dismissNotificationAlertIfNeeded() -> MySiteScreen {
        if FancyAlertComponent.isLoaded() {
            FancyAlertComponent().cancelAlert()
        }
        return self
    }

    func switchSite() -> MySitesScreen {
        app.buttons["Switch Site"].tap()

        return MySitesScreen()
    }

    func removeSelfHostedSite() {
        removeSiteButton.tap()
        if isIpad() {
            _ = waitFor(element: removeSiteAlert, predicate: "isHittable == true")
            removeSiteAlert.tap()
        } else {
            _ = waitFor(element: removeSiteSheet, predicate: "isHittable == true")
            removeSiteSheet.tap()
        }
    }
}
