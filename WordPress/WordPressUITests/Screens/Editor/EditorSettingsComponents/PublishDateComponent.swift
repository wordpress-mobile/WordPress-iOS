import UITestsFoundation
import XCTest

class PublishDateComponent: BaseScreen {
    let dateAndTimeButton: XCUIElement
    let nextButton: XCUIElement
    let doneButton: XCUIElement
    let postSettingsButton: XCUIElement
    init() {
        let app = XCUIApplication()
        dateAndTimeButton = app.staticTexts.element(boundBy: 1) // identify element by position
        nextButton = app.buttons["Next"]
        doneButton = app.buttons["Done"]
        postSettingsButton = app.buttons["Post Settings"]
        super.init(element: postSettingsButton)
    }

    func setForNextThreeHours() -> PublishDateComponent {
        dateAndTimeButton.tap()
        nextButton.tap()
        doneButton.tap()
        return self
    }

    func goBackToSettings() -> EditorPostSettings {
        postSettingsButton.tap()
        return EditorPostSettings()
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().textViews["Date and Time, Immediately"].exists
    }
}
