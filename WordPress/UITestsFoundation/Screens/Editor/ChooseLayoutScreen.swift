import ScreenObject
import XCTest

public class ChooseLayoutScreen: ScreenObject {

    private let closeButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Close"]
    }

    private let createBlankPageButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Create Blank Page"]
    }

    var closeButton: XCUIElement { closeButtonGetter(app) }
    var createBlankPageButton: XCUIElement { createBlankPageButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [closeButtonGetter],
            app: app
        )
    }

    @discardableResult
    public func closeModal() throws -> MySiteScreen {
        closeButton.tap()
        return try MySiteScreen()
    }

    @discardableResult
    public func createBlankPage() throws -> BlockEditorScreen {
        createBlankPageButton.tap()

        return try BlockEditorScreen()
    }

    public static func isLoaded() -> Bool {
        (try? ChooseLayoutScreen().isLoaded) ?? false
    }
}
