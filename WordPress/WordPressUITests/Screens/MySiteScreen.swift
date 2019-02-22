import Foundation
import XCTest

private struct ElementStringIDs {
    static let blogTable = "Blog Details Table"
    static let removeSiteButton = "BlogDetailsRemoveSiteCell"
    static let removeSiteConfirmation = "Remove Site"
    static let switchSiteButton = "Switch Site"
}

class MySiteScreen: BaseScreen {
    let tabBar: TabNavComponent
    let removeSiteButton: XCUIElement
    let removeSiteSheet: XCUIElement
    let removeSiteAlert: XCUIElement

    init() {
        let app = XCUIApplication()
        let blogTable = app.tables[ElementStringIDs.blogTable]
        tabBar = TabNavComponent()
        removeSiteButton = app.cells[ElementStringIDs.removeSiteButton]
        removeSiteSheet = app.sheets.buttons[ElementStringIDs.removeSiteConfirmation]
        removeSiteAlert = app.alerts.buttons[ElementStringIDs.removeSiteConfirmation]

        super.init(element: blogTable)
    }

    func dismissNotificationAlertIfNeeded() -> MySiteScreen {
        if FancyAlertComponent.isLoaded() {
            FancyAlertComponent().cancelAlert()
        }
        return self
    }

    func switchSite() -> MySitesScreen {
        app.buttons[ElementStringIDs.switchSiteButton].tap()

        return MySitesScreen()
    }

    func removeSelfHostedSite() {
        removeSiteButton.tap()
        if isIpad() {
            removeSiteAlert.tap()
        } else {
            removeSiteSheet.tap()
        }
    }
}
