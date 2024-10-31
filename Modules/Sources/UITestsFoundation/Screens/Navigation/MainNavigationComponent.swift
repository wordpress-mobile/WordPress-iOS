import ScreenObject
import XCTest
import UIKit

public protocol MainNavigationComponent {
    func goToReaderScreen() throws
    func goToNotificationsScreen() throws -> NotificationsScreen
    func goToMeScreen() throws -> MeTabScreen
}

public func makeMainNavigationComponent() throws -> MainNavigationComponent {
    if XCTestCase.isPad {
        // Assuming the app is used in the fullscreen mode.
        return try SidebarNavComponent()
    } else {
        return try TabNavComponent()
    }
}
