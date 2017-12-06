import Foundation
import XCTest

class MySitesScreen: BaseScreen {
    let tabBar: TabNavComponent
    init() {
        let navBar = XCUIApplication().navigationBars.element(boundBy: 0)
        tabBar = TabNavComponent.init()

        super.init(element: navBar)
    }
}
