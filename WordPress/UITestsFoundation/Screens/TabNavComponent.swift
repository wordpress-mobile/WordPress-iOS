import ScreenObject
import XCTest

public class TabNavComponent: ScreenObject {

    private static let tabBarGetter: (XCUIApplication) -> XCUIElement = {
        $0.tabBars["Main Navigation"]
    }

    private let mySitesTabButtonGetter: (XCUIApplication) -> XCUIElement = {
        TabNavComponent.tabBarGetter($0).buttons["mySitesTabButton"]
    }

    private let readerTabButtonGetter: (XCUIApplication) -> XCUIElement = {
        TabNavComponent.tabBarGetter($0).buttons["readerTabButton"]
    }

    private let notificationsTabButtonGetter: (XCUIApplication) -> XCUIElement = {
        TabNavComponent.tabBarGetter($0).buttons["notificationsTabButton"]
    }

    var mySitesTabButton: XCUIElement { mySitesTabButtonGetter(app) }
    var readerTabButton: XCUIElement { readerTabButtonGetter(app) }
    var notificationsTabButton: XCUIElement { notificationsTabButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                mySitesTabButtonGetter,
                readerTabButtonGetter,
                notificationsTabButtonGetter
            ],
            app: app,
            waitTimeout: 3
        )
    }

    public func goToMeScreen() throws -> MeTabScreen {
        try goToMySiteScreen()
        let meButton = app.navigationBars.buttons["meBarButton"]
        meButton.tap()
        return try MeTabScreen()
    }

    @discardableResult
    public func goToMySiteScreen() throws -> MySiteScreen {
        mySitesTabButton.tap()
        return try MySiteScreen()
    }

    public func goToAztecEditorScreen() throws -> AztecEditorScreen {
        let mySiteScreen = try goToMySiteScreen()
        let actionSheet = try mySiteScreen.gotoCreateSheet()
        actionSheet.goToBlogPost()

        return try AztecEditorScreen(mode: .rich)
    }

    public func gotoBlockEditorScreen() throws -> BlockEditorScreen {
        let mySite = try goToMySiteScreen()
        let actionSheet = try mySite.gotoCreateSheet()
        actionSheet.goToBlogPost()

        return try BlockEditorScreen()
    }

    public func goToReaderScreen() throws -> ReaderScreen {
        readerTabButton.tap()
        return try ReaderScreen()
    }

    public func goToNotificationsScreen() throws -> NotificationsScreen {
        notificationsTabButton.tap()
        return try NotificationsScreen()
    }

    public static func isLoaded() -> Bool {
        (try? TabNavComponent().isLoaded) ?? false
    }

    public static func isVisible() -> Bool {
        guard let screen = try? TabNavComponent() else { return false }
        return screen.mySitesTabButton.isHittable
    }
}
