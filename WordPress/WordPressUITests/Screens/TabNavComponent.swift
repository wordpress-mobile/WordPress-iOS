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
        gotoMySitesScreen()
        app.cells[WPUITestCredentials.testWPcomSitePrimaryAddress].tap()
        let meButton = app.navigationBars.buttons["meBarButton"]
        meButton.tap()
        return MeTabScreen()
    }

    @discardableResult
    func gotoMySiteScreen() -> MySiteScreen {
        // Avoid transitioning to the sites list if MySites is already on screen
        if !MySiteScreen.isVisible {
            gotoMySitesScreen().switchToSite(withTitle: "infocusphotographers.com")
        }
        return MySiteScreen()
    }

    @discardableResult
    func gotoMySitesScreen() -> MySitesScreen {
        mySitesTabButton.tap()
        mySitesTabButton.tap()
        return MySitesScreen()
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
