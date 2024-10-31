import ScreenObject
import XCTest

/// Represents the main app-wide sidebar.
public class SidebarScreen: ScreenObject {
    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init {
            $0.collectionViews["sidebar_list"].firstMatch
        }
    }

    public func openMeScreen() throws -> MeTabScreen {
        app.buttons["sidebar_me"].firstMatch.tap()
        return try MeTabScreen()
    }

    public func openReaderScreen() {
        app.staticTexts["sidebar_reader"].firstMatch.tap()
        app.swipeLeft() // Close the sidebar
    }

    public func openNotificationsScreen() throws -> NotificationsScreen {
        app.staticTexts["sidebar_notifications"].firstMatch.tap()
        return try NotificationsScreen()
    }
}
