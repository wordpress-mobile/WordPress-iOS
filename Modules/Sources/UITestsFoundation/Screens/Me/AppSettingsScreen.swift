import ScreenObject
import XCTest

public class AppSettingsScreen: ScreenObject {

    private let backButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.navigationBars.buttons.element(boundBy: 0)
    }

    private let imageOptimizationSwitchGetter: (XCUIApplication) -> XCUIElement = {
        $0.switches["imageOptimizationSwitch"]
    }

    var backButton: XCUIElement { backButtonGetter(app) }
    var imageOptimizationSwitch: XCUIElement { imageOptimizationSwitchGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                imageOptimizationSwitchGetter,
            ],
            app: app
        )
    }

    public func tapImageOptimizationSwitch() throws -> Self {
        imageOptimizationSwitch.tap()
        return self
    }

    @discardableResult
    public func verifyImageOptimizationSwitch(enabled: Bool) -> Self {
        XCTAssertEqual(imageOptimizationSwitch.value as? String, enabled ? "1" : "0")
        return self
    }

    public func dismiss() throws -> MeTabScreen {
        backButton.tap()
        return try MeTabScreen()
    }

    static func isLoaded() -> Bool {
        (try? AppSettingsScreen().isLoaded) ?? false
    }
}
