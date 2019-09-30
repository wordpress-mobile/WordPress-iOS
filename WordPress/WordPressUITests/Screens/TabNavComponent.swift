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
        // Avoid transitioning to the sites list if MySites is already on screen
        if !MySiteScreen.isVisible {
            mySitesTabButton.tap()
        }
        return MySiteScreen()
    }

    func gotoMySitesScreen() -> MySitesScreen {
        mySitesTabButton.tap()
        mySitesTabButton.tap()
        return MySitesScreen()
    }

    func gotoAztecEditorScreen() -> AztecEditorScreen {
        writeTabButton.tap()
        return AztecEditorScreen(mode: .rich)
    }

    func gotoBlockEditorScreen() -> BlockEditorScreen {
        writeTabButton.tap()
        return BlockEditorScreen()
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
