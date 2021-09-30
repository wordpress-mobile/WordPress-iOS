import XCTest

private struct ElementStringIDs {
    static let draftsButton = "drafts"
}

public class StatsScreen: BaseScreen {

    public enum Mode: String {
        case months = "months"
        case years = "years"
    }

    struct ElementStringIDs {
        static let dismissCustomizeInsightsButton = "dismiss-customize-insights-cell"
    }

    public init() {
        super.init(element: XCUIApplication().otherElements.firstMatch)
    }

    @discardableResult
    public func dismissCustomizeInsightsNotice() -> StatsScreen {
        let button = XCUIApplication().buttons[ElementStringIDs.dismissCustomizeInsightsButton]

        if button.exists {
            button.tap()
        }

        return self
    }

    @discardableResult
    public func switchTo(mode: Mode) -> StatsScreen {
        XCUIApplication().buttons[mode.rawValue].tap()
        return self
    }
}
