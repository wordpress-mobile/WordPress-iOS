import ScreenObject
import XCTest

public class PrepublishingSheetScreen: ScreenObject {

    private let categoriesSectionGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["Categories"]
    }

    private let tagsSectionGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["Tags"]
    }

    private let publishDateButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["Date"]
    }

    private let closeButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.navigationBars.buttons["close"]
    }

    private let publishButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["publish"]
    }

    var categoriesSection: XCUIElement { categoriesSectionGetter(app) }
    var closeButton: XCUIElement { closeButtonGetter(app) }
    var publishDateButton: XCUIElement { publishDateButtonGetter(app) }
    var tagsSection: XCUIElement { tagsSectionGetter(app) }
    var publishButton: XCUIElement { publishButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(expectedElementGetters: [publishButtonGetter], app: app)
    }

    public func selectCategory(name: String) throws -> EditorPostSettings {
        return try openCategories()
            .selectCategory(name: name)
            .goBackToSettings()
    }

    public func addTag(name: String) throws -> EditorPostSettings {
        return try openTags()
            .addTag(name: name)
            .goBackToSettings()
    }

    func openCategories() throws -> CategoriesComponent {
        categoriesSection.tap()

        return try CategoriesComponent()
    }

    func openTags() throws -> TagsComponent {
        tagsSection.tap()

        return try TagsComponent()
    }

    public static func isLoaded() -> Bool {
        return (try? PrepublishingSheetScreen().isLoaded) ?? false
    }

    @discardableResult
    public func updatePublishDateToFutureDate() throws -> Self {
        publishDateButton.tap()
        try PostSettingsPublishDateScreen()
            .updatePublishDateToFutureDate()
            .closePublishDateSelector()
        return self
    }

    public func closePublishDateSelector() -> Self {
        let backButton = app.navigationBars["Publish Date"].buttons.element(boundBy: 0)
        backButton.tap()
        return self
    }

    public func confirm() {
        publishButton.tap()
    }
}
