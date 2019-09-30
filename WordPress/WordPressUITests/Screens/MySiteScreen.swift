import Foundation
import XCTest

private struct ElementStringIDs {
    static let blogTable = "Blog Details Table"
    static let removeSiteButton = "BlogDetailsRemoveSiteCell"
    static let settingsButton = "Settings Row"
}

class MySiteScreen: BaseScreen {
    let tabBar: TabNavComponent
    let removeSiteButton: XCUIElement
    let removeSiteSheet: XCUIElement
    let removeSiteAlert: XCUIElement
    let siteSettingsButton: XCUIElement

    static var isVisible: Bool {
        let app = XCUIApplication()
        let blogTable = app.tables[ElementStringIDs.blogTable]
        return blogTable.isHittable
    }

    init() {
        let app = XCUIApplication()
        let blogTable = app.tables[ElementStringIDs.blogTable]
        tabBar = TabNavComponent()
        removeSiteButton = app.cells[ElementStringIDs.removeSiteButton]
        removeSiteSheet = app.sheets.buttons.element(boundBy: 0)
        removeSiteAlert = app.alerts.buttons.element(boundBy: 1)
        siteSettingsButton = app.cells[ElementStringIDs.settingsButton]

        super.init(element: blogTable)
    }

    func dismissNotificationAlertIfNeeded() -> MySiteScreen {
        if FancyAlertComponent.isLoaded() {
            FancyAlertComponent().cancelAlert()
        }
        return self
    }

    func switchSite() -> MySitesScreen {
        navBackButton.tap()

        return MySitesScreen()
    }

    func removeSelfHostedSite() {
        removeSiteButton.tap()
        if isIpad {
            removeSiteAlert.tap()
        } else {
            removeSiteSheet.tap()
        }
    }

    func gotoSettingsScreen() -> SiteSettingsScreen {
        siteSettingsButton.tap()
        return SiteSettingsScreen()
    }
}
