import ScreenObject
import XCTest

public class PlanSelectionScreen: ScreenObject {
    private let webViewGetter: (XCUIApplication) -> XCUIElement = {
        $0.webViews.firstMatch
    }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ webViewGetter ],
            app: app,
            waitTimeout: 7
        )
    }

    public static func isLoaded() -> Bool {
        (try? PlanSelectionScreen().isLoaded) ?? false
    }
}
