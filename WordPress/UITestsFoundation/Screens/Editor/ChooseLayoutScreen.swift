import ScreenObject
import XCTest

public class ChooseLayoutScreen: ScreenObject {

    let closeButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Close"]
    }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [closeButtonGetter],
            app: app,
            waitTimeout: 7
        )
    }

    @discardableResult
    public func closeModal() throws -> MySiteScreen {
        closeButtonGetter(app).tap()
        return try MySiteScreen()
    }

    public static func isLoaded() -> Bool {
        (try? ChooseLayoutScreen().isLoaded) ?? false
    }
}
