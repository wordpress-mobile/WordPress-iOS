import ScreenObject
import XCTest

public class FeatureIntroductionScreen: ScreenObject {
    private let closeButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["close-button"]
    }

    var closeButton: XCUIElement { closeButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [closeButtonGetter],
            app: app,
            waitTimeout: 7
        )
    }

    public func dismiss() throws -> MySiteScreen {
        closeButton.tap()

        return try MySiteScreen()
    }

    static func isLoaded() -> Bool {
        (try? FeatureIntroductionScreen().isLoaded) ?? false
    }
}
