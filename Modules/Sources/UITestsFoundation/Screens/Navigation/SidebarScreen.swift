import ScreenObject
import XCTest

/// Represents the main app-wide sidebar.
public class SidebarScreen: ScreenObject {
    public init(app: XCUIApplication = XCUIApplication()) throws {
        // The sidebar_list CollectionView (SwiftUI List with .sidebar style) reports
        // isVisible == false in UISplitViewController's sidebar column due to a
        // UIKit/SwiftUI accessibility quirk, making isHittable always fail.
        // Use the sidebar_me button instead, which correctly reports visibility.
        try super.init {
            $0.buttons["sidebar_me"].firstMatch
        }
    }

    public func openMeScreen() throws -> MeTabScreen {
        app.buttons["sidebar_me"].firstMatch.tap()
        return try MeTabScreen()
    }

    public func openReaderScreen() {
        app.staticTexts["sidebar_reader"].firstMatch.tap()
    }

    public func openNotificationsScreen() throws -> NotificationsScreen {
        app.staticTexts["sidebar_notifications"].firstMatch.tap()
        return try NotificationsScreen()
    }
}
