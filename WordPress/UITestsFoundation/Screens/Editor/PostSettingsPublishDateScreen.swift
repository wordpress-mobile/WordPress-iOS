import ScreenObject
import XCTest

public class PostSettingsPublishDateScreen: ScreenObject {
    private let nextMonthButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Next Month"]
    }

    private let monthLabelGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Month"]
    }

    private let firstCalendarDayButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons.containing(.staticText, identifier: "1").element
    }

    private let backButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.navigationBars["Publish Date"].buttons.element(boundBy: 0)
    }

    var backButton: XCUIElement { backButtonGetter(app) }
    var firstCalendarDayButton: XCUIElement { firstCalendarDayButtonGetter(app) }
    var monthLabel: XCUIElement { monthLabelGetter(app) }
    var nextMonthButton: XCUIElement { nextMonthButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(expectedElementGetters: [monthLabelGetter], app: app)
    }

    @discardableResult
    public func updatePublishDateToFutureDate() -> Self {
        let currentMonth = monthLabel.value as! String

        // Selects the first day of the next month
        nextMonthButton.tap()

        // To ensure that the day tap happens on the correct month
        let nextMonth = monthLabel.value as! String
        if nextMonth != currentMonth {
            firstCalendarDayButton.tapUntil(.selected, failureMessage: "First Day button not selected!")
        }
        return self
    }

    public func closePublishDateSelector() {
        backButton.tap()
    }
}
