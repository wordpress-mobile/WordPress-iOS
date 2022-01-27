import ScreenObject
import XCTest

public class QuickStartPromptScreen: ScreenObject {

    private let noThanksButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["No thanks"]
    }

    var noThanksButton: XCUIElement { noThanksButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [noThanksButtonGetter],
            app: app,
            waitTimeout: 7
        )
    }

    public func selectNoThanks() throws -> MySiteScreen {
        noThanksButton.tap()

        return try MySiteScreen()
    }

    static func isLoaded() -> Bool {
        (try? QuickStartPromptScreen().isLoaded) ?? false
    }
}
