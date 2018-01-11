import Foundation
import XCTest

class MySitesScreen: BaseScreen {
    let tabBar: TabNavComponent

    init() {
        let blogsTable = XCUIApplication().tables["Blogs"]
        tabBar = TabNavComponent()

        super.init(element: blogsTable)
    }
}
