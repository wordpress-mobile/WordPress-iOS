import Foundation
import XCTest

class CategoriesComponent: BaseScreen {
    let header: XCUIElement
    let backButton: XCUIElement

    init() {
        let app = XCUIApplication()
        header = app.navigationBars["Azctec Editor Navigation Bar"].otherElements["Post Categories"]
        backButton = app.buttons["Post Settings"]

        super.init(element: header)
    }

    func selectCategory(name: String) -> CategoriesComponent {
        let category = app.cells.staticTexts[name]
        category.tap()

        return self
    }

    func goBackToSettings() -> EditorPostSettings {
        backButton.tap()

        return EditorPostSettings()
    }
}
