import ScreenObject
import XCTest

public class SidebarNavComponent: ScreenObject, MainNavigationComponent {
    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init {
            $0.otherElements["root_vc"].firstMatch
        }
    }

    public func goToMeScreen() throws -> MeTabScreen {
        try openSidebar().openMeScreen()
    }

    public func goToReaderScreen() throws {
        try openSidebar().openReaderScreen()
    }

    public func goToNotificationsScreen() throws -> NotificationsScreen {
        try openSidebar().openNotificationsScreen()
    }

    public func openSidebar() throws -> SidebarScreen {
        try openSiteMenu().openSidebar()
    }

    @discardableResult
    public func openSiteMenu() throws -> SidebarSiteMenuScreen {
        app.buttons["ToggleSidebar"].firstMatch.tap()
        return try SidebarSiteMenuScreen()
    }
}
