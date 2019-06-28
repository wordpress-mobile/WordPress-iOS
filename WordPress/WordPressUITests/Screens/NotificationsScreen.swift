import Foundation
import XCTest

class NotificationsScreen: BaseScreen {
    let tabBar: TabNavComponent

    init() {
        let navBar = XCUIApplication().tables["Notifications Table"]
        tabBar = TabNavComponent()

        super.init(element: navBar)
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().tables["Notifications Table"].exists
    }
}
