import ScreenObject
import XCTest

public class CategoriesComponent: ScreenObject {

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ { $0.tables["CategoriesList"] } ],
            app: app,
            waitTimeout: 7
        )
    }

    public func selectCategory(name: String) -> CategoriesComponent {
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
