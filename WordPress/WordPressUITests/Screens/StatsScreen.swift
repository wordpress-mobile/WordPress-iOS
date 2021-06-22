import UITestsFoundation
import XCTest

private struct ElementStringIDs {
    static let draftsButton = "drafts"
}

class StatsScreen: BaseScreen {

    enum Mode: String {
        case months = "months"
        case years = "years"
    }

    struct ElementStringIDs {
        static let dismissCustomizeInsightsButton = "dismiss-customize-insights-cell"
    }

    init() {
        super.init(element: XCUIApplication().otherElements.firstMatch)
    }

    @discardableResult
    func dismissCustomizeInsightsNotice() -> StatsScreen {
        let button = XCUIApplication().buttons[ElementStringIDs.dismissCustomizeInsightsButton]

        if button.exists {
            button.tap()
        }

        return self
    }

    @discardableResult
    func switchTo(mode: Mode) -> StatsScreen {
        XCUIApplication().buttons[mode.rawValue].tap()
        return self
    }
}
