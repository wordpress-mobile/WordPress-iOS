import Foundation
import XCTest

class TabNavComponent: BaseScreen {

    let meTabButton: XCUIElement
    let mySitesTabButton: XCUIElement
    let readerTabButton: XCUIElement
    let writeTabButton: XCUIElement
    let notificationsTabButton: XCUIElement

    init() {
        let tabBars = XCUIApplication().tabBars["Main Navigation"]
        mySitesTabButton = tabBars.buttons["mySitesTabButton"]
        readerTabButton = tabBars.buttons["readerTabButton"]
        writeTabButton = tabBars.buttons["Write"]
        notificationsTabButton = tabBars.buttons["notificationsTabButton"]
        meTabButton = tabBars.buttons["meTabButton"]
        super.init(element: meTabButton)
    }

    func gotoMeScreen() -> MeTabScreen {
        meTabButton.tap()
        return MeTabScreen.init()
    }

    func gotoMySitesScreen() -> MySitesScreen {
        mySitesTabButton.tap()
        return MySitesScreen.init()
    }
}
