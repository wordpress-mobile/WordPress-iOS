import Foundation
import XCTest

class MySiteScreen: BaseScreen {
    let tabBar: TabNavComponent
    let removeSiteButton: XCUIElement
    let removeSiteConfirmation: XCUIElement

    init() {
        let app = XCUIApplication()
        let blogTable = app.tables["Blog Details Table"]
        tabBar = TabNavComponent()
        removeSiteButton = app.cells["BlogDetailsRemoveSiteCell"]
        removeSiteConfirmation = app.sheets.buttons["Remove Site"]

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
        _ = waitFor(element: removeSiteConfirmation, predicate: "isHittable == true")
        removeSiteConfirmation.tap()
    }
}
