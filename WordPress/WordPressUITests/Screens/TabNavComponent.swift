import Foundation
import XCTest

class TabNavComponent: BaseScreen {

    let mySitesTabButton: XCUIElement
    let readerTabButton: XCUIElement
    let notificationsTabButton: XCUIElement

    init() {
        let tabBars = XCUIApplication().tabBars["Main Navigation"]
        mySitesTabButton = tabBars.buttons["mySitesTabButton"]
        readerTabButton = tabBars.buttons["readerTabButton"]
        notificationsTabButton = tabBars.buttons["notificationsTabButton"]
        super.init(element: mySitesTabButton)
    }

    func gotoMeScreen() -> MeTabScreen {
        gotoMySiteScreen()
        let meButton = app.navigationBars.buttons["meBarButton"]
        meButton.tap()
        return MeTabScreen()
    }

    @discardableResult
    func gotoMySiteScreen() -> MySiteScreen {
        mySitesTabButton.tap()
        return MySiteScreen()
    }

    func gotoAztecEditorScreen() -> AztecEditorScreen {
        let mySiteScreen = gotoMySiteScreen()
        let actionSheet = mySiteScreen.gotoCreateSheet()
        actionSheet.gotoBlogPost()

        return AztecEditorScreen(mode: .rich)
    }

    func gotoBlockEditorScreen() -> BlockEditorScreen {
        let mySite = gotoMySiteScreen()
        let actionSheet = mySite.gotoCreateSheet()
        actionSheet.gotoBlogPost()

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
