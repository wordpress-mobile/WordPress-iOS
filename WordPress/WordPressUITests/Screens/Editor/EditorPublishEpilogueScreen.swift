import Foundation
import XCTest

class EditorPublishEpilogueScreen: BaseScreen {
    let doneButton: XCUIElement
    let viewButton: XCUIElement

    init() {
        let app = XCUIApplication()
        let published = app.staticTexts["Published just now on"]
        doneButton = app.navigationBars.buttons["Done"]
        viewButton = app.buttons["View Post"]

        super.init(element: published)
    }

    func done() -> MySiteScreen {
        doneButton.tap()
        return MySiteScreen()
    }
}
