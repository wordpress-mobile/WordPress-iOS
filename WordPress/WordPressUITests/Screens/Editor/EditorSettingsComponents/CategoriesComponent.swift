import Foundation
import XCTest

class CategoriesComponent: BaseScreen {
    let categoriesList: XCUIElement
    let backButton: XCUIElement

    init() {
        let app = XCUIApplication()
        categoriesList = app.tables["CategoriesList"]
        backButton = app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0)

        super.init(element: categoriesList)
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

    static func isLoaded() -> Bool {
        return XCUIApplication().tables["CategoriesList"].exists
    }
}
