import XCTest

public class TabNavComponent: BaseScreen {

    let mySitesTabButton: XCUIElement
    let readerTabButton: XCUIElement
    let notificationsTabButton: XCUIElement

    public init() {
        let tabBars = XCUIApplication().tabBars["Main Navigation"]
        mySitesTabButton = tabBars.buttons["mySitesTabButton"]
        readerTabButton = tabBars.buttons["readerTabButton"]
        notificationsTabButton = tabBars.buttons["notificationsTabButton"]
        super.init(element: mySitesTabButton)
    }

    public func gotoMeScreen() throws -> MeTabScreen {
        gotoMySiteScreen()
        let meButton = app.navigationBars.buttons["meBarButton"]
        meButton.tap()
        return try MeTabScreen()
    }

    @discardableResult
    public func gotoMySiteScreen() -> MySiteScreen {
        mySitesTabButton.tap()
        return MySiteScreen()
    }

    public func gotoAztecEditorScreen() throws -> AztecEditorScreen {
        let mySiteScreen = gotoMySiteScreen()
        let actionSheet = try mySiteScreen.gotoCreateSheet()
        actionSheet.goToBlogPost()

        return AztecEditorScreen(mode: .rich)
    }

    public func gotoBlockEditorScreen() throws -> BlockEditorScreen {
        let mySite = gotoMySiteScreen()
        let actionSheet = try mySite.gotoCreateSheet()
        actionSheet.goToBlogPost()

        return BlockEditorScreen()
    }

    public func gotoReaderScreen() -> ReaderScreen {
        readerTabButton.tap()
        return ReaderScreen()
    }

    public func gotoNotificationsScreen() -> NotificationsScreen {
        notificationsTabButton.tap()
        return NotificationsScreen()
    }

    public static func isLoaded() -> Bool {
        return XCUIApplication().buttons["mySitesTabButton"].exists
    }

    public static func isVisible() -> Bool {
        return XCUIApplication().buttons["mySitesTabButton"].isHittable
    }
}
