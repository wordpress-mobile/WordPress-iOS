import ScreenObject
import XCTest

public class TabNavComponent: ScreenObject {

    private static let tabBarGetter: (XCUIApplication) -> XCUIElement = {
        $0.tabBars["Main Navigation"]
    }

    private let mySitesTabButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.tabBars["Main Navigation"].buttons["mySitesTabButton"]
    }

    private let readerTabButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.tabBars["Main Navigation"].buttons["readerTabButton"]
    }

    private let notificationsTabButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.tabBars["Main Navigation"].buttons["notificationsTabButton"]
    }

    private let meTabButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.navigationBars.buttons["meBarButton"]
    }

    var meTabButton: XCUIElement { meTabButtonGetter(app) }
    var mySitesTabButton: XCUIElement { mySitesTabButtonGetter(app) }
    var notificationsTabButton: XCUIElement { notificationsTabButtonGetter(app) }
    var readerTabButton: XCUIElement { readerTabButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                mySitesTabButtonGetter,
                notificationsTabButtonGetter,
                readerTabButtonGetter
            ],
            app: app
        )
    }

    // Removed the MeTabScreen return value because MeTabScreen is a modal on top of MySiteScreen on iPad
    // Returning it causes flakiness in CI as MySiteScreen is loaded first, making the test look for elements on MySiteScreen instead of MeTabScreen
    public func goToMeScreen() throws {
        try goToMySiteScreen()
        meTabButton.tap()
    }

    @discardableResult
    public func goToMySiteScreen() throws -> MySiteScreen {
        mySitesTabButton.tap()
        return try MySiteScreen()
    }

    public func goToAztecEditorScreen() throws -> AztecEditorScreen {
        let mySiteScreen = try goToMySiteScreen()
        let actionSheet = try mySiteScreen.goToCreateSheet()
        actionSheet.goToBlogPost()

        return try AztecEditorScreen(mode: .rich)
    }

    @discardableResult
    public func goToBlockEditorScreen() throws -> BlockEditorScreen {
        try goToMySiteScreen()
            .goToCreateSheet()
            .goToBlogPost()

        return try BlockEditorScreen()
    }

    @discardableResult
    public func goToReaderScreen() throws -> ReaderScreen {
        readerTabButton.tap()
        return try ReaderScreen()
    }

    public func goToNotificationsScreen() throws -> NotificationsScreen {
        notificationsTabButton.tap()
        try dismissNotificationAlertIfNeeded()
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
