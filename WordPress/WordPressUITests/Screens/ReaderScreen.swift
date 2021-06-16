import UITestsFoundation
import XCTest

private struct ElementStringIDs {
    static let readerTable = "Reader"
    static let discoverButton = "Discover"
}

class ReaderScreen: BaseScreen {
    let tabBar: TabNavComponent
    let discoverButton: XCUIElement

    init() {
        let readerTable = XCUIApplication().tables[ElementStringIDs.readerTable]
        tabBar = TabNavComponent()
        discoverButton = XCUIApplication().buttons[ElementStringIDs.discoverButton]

        super.init(element: readerTable)
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().tables[ElementStringIDs.readerTable].exists
    }

    func openDiscover() -> ReaderScreen {
        discoverButton.tap()

        return self
    }
}
