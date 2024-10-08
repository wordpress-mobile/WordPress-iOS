import ScreenObject
import XCTest

/// Represents the site menu displayed in the supplementary column on iPad.
public class SidebarSiteMenuScreen: ScreenObject {
    var navigationBar: XCUIElement {
        app.navigationBars["site_menu_navbar"].firstMatch
    }

    var table: XCUIElement {
        app.tables["Blog Details Table"].firstMatch
    }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init {
            $0.navigationBars["site_menu_navbar"].firstMatch
        }
    }

    func openSidebar() throws -> SidebarScreen {
        navigationBar.buttons.element(boundBy: 0).tap()
        return try SidebarScreen()
    }

    public func removeSelfHostedSite() {
        table.swipeUp(velocity: .fast)
        table.cells["BlogDetailsRemoveSiteCell"].tap()
        app.alerts.buttons.element(boundBy: 1).tap()
    }
}
