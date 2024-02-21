import ScreenObject
import XCTest

public class CategoriesComponent: ScreenObject {

    private let categoriesListGetter: (XCUIApplication) -> XCUIElement = {
        $0.tables["CategoriesList"]
    }

    var categoriesList: XCUIElement { categoriesListGetter(app) }

    var backButton: XCUIElement {
        app.navigationBars["Post Categories"]
            .buttons.element(boundBy: 0)
    }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ categoriesListGetter ],
            app: app
        )
    }

    public func selectCategory(name: String) -> Self {
        let category = app.cells.staticTexts[name]
        category.tap()

        return self
    }

    func goBackToSettings() throws -> EditorPostSettings {
        backButton.tap()

        return try EditorPostSettings()
    }

    public static func isLoaded() -> Bool {
        (try? CategoriesComponent().isLoaded) ?? false
    }
}
