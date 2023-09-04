import ScreenObject
import XCTest

public class ChooseLayoutScreen: ScreenObject {

    private let closeButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Close"]
    }

    var closeButton: XCUIElement { closeButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
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

    public static func isLoaded() -> Bool {
        (try? ChooseLayoutScreen().isLoaded) ?? false
    }
}
