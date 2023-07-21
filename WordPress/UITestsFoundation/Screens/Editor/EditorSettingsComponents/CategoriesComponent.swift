import ScreenObject
import XCTest

public class CategoriesComponent: ScreenObject {

    private let categoriesListGetter: (XCUIApplication) -> XCUIElement = {
        $0.tables["CategoriesList"]
    }

    var categoriesList: XCUIElement { categoriesListGetter(app) }

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
        navigateBack()

        return try EditorPostSettings()
    }

    public static func isLoaded() -> Bool {
        (try? CategoriesComponent().isLoaded) ?? false
    }
}
