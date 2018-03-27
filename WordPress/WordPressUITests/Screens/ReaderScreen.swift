import Foundation
import XCTest

class ReaderScreen: BaseScreen {
    let tabBar: TabNavComponent

    init() {
        let readerTable = XCUIApplication().tables["Reader"]
        tabBar = TabNavComponent()

        super.init(element: readerTable)
    }
}
