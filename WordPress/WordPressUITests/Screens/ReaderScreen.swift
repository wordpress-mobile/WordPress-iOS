import Foundation
import XCTest

private struct ElementStringIDs {
    static let readerTable = "Reader"
}

class ReaderScreen: BaseScreen {
    let tabBar: TabNavComponent

    init() {
        let readerTable = XCUIApplication().tables[ElementStringIDs.readerTable]
        tabBar = TabNavComponent()

        super.init(element: readerTable)
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().tables[ElementStringIDs.readerTable].exists
    }
}
