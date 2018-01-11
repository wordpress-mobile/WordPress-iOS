import Foundation
import XCTest

class NotificationsScreen: BaseScreen {
    let tabBar: TabNavComponent

    init() {
        let navBar = XCUIApplication().navigationBars["Notifications"]
        tabBar = TabNavComponent()

        super.init(element: navBar)
    }
}
