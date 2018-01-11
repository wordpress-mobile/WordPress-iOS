import Foundation
import XCTest

class MySitesScreen: BaseScreen {
    let tabBar: TabNavComponent

    init() {
        tabBar = TabNavComponent()
        let blogsTable = XCUIApplication().tables["Blogs"]

        super.init(element: blogsTable)
    }
}
