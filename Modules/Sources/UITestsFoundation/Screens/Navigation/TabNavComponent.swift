import ScreenObject
import XCTest
import UIKit

public class TabNavComponent: ScreenObject, MainNavigationComponent {
    var mySitesTabButton: XCUIElement {
        app.buttons["tabbar_mysites"].firstMatch
    }

    var notificationsTabButton: XCUIElement {
        app.buttons["tabbar_notifications"].firstMatch
    }

    var readerTabButton: XCUIElement {
        app.buttons["tabbar_reader"].firstMatch
    }

    var meTabButton: XCUIElement {
        app.buttons["tabbar_me"].firstMatch
    }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init {
            $0.tabBars["Main Navigation"].firstMatch
        }
    }

    public func goToMeScreen() throws -> MeTabScreen {
        try goToMySiteScreen()
        meTabButton.tap()
        return try MeTabScreen()
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

    public func goToReaderScreen() throws {
        readerTabButton.tap()
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
