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
        return MeTabScreen()
    }

    func gotoMySiteScreen() -> MySiteScreen {
        mySitesTabButton.tap()
        return MySiteScreen()
    }

    func gotoMySitesScreen() -> MySitesScreen {
        mySitesTabButton.tap()
        mySitesTabButton.tap()
        return MySitesScreen()
    }

    func gotoEditorScreen() -> EditorScreen {
        writeTabButton.tap()
        return EditorScreen(mode: .rich)
    }

    func gotoReaderScreen() -> ReaderScreen {
        readerTabButton.tap()
        return ReaderScreen()
    }

    func gotoNotificationsScreen() -> NotificationsScreen {
        notificationsTabButton.tap()
        return NotificationsScreen()
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().buttons["mySitesTabButton"].exists
    }

    static func isVisible() -> Bool {
        return XCUIApplication().buttons["mySitesTabButton"].isHittable
    }
}
