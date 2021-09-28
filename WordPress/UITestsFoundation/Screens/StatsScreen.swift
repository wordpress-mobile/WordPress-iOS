import ScreenObject
import XCTest

public class StatsScreen: ScreenObject {

    public enum Mode: String {
        case months
        case years
    }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [{ $0.otherElements.firstMatch }],
            app: app
        )
    }

    @discardableResult
    public func dismissCustomizeInsightsNotice() -> StatsScreen {
        let button = app.buttons["dismiss-customize-insights-cell"]

        if button.exists {
            button.tap()
        }

        return self
    }

    @discardableResult
    public func switchTo(mode: Mode) -> StatsScreen {
        app.buttons[mode.rawValue].tap()
        return self
    }
}
