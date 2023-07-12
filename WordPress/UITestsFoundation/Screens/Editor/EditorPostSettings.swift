import ScreenObject
import XCTest

public class EditorPostSettings: ScreenObject {

    let settingsTableGetter: (XCUIApplication) -> XCUIElement = {
        $0.tables["SettingsTable"]
    }

    let categoriesSectionGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["Categories"]
    }

    let tagsSectionGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["Tags"]
    }

    let featuredImageButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["SetFeaturedImage"]
    }

    let currentFeaturedImageGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["CurrentFeaturedImage"]
    }

    let publishDateButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["Publish Date"]
    }

    let dateSelectorGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["Immediately"]
    }

    let nextMonthButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Next Month"]
    }

    let firstCalendarDayLabelGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["1"]
    }

    let doneButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Done"]
    }

    var settingsTable: XCUIElement { settingsTableGetter(app) }
    var categoriesSection: XCUIElement { categoriesSectionGetter(app) }
    var tagsSection: XCUIElement { tagsSectionGetter(app) }
    var featuredImageButton: XCUIElement { featuredImageButtonGetter(app) }
    var currentFeaturedImage: XCUIElement { currentFeaturedImageGetter(app) }
    var publishDateButton: XCUIElement { publishDateButtonGetter(app) }
    var dateSelector: XCUIElement { dateSelectorGetter(app) }
    var nextMonthButton: XCUIElement { nextMonthButtonGetter(app) }
    var firstCalendarDayLabel: XCUIElement { firstCalendarDayLabelGetter(app) }
    var doneButton: XCUIElement { doneButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ settingsTableGetter ],
            app: app
        )
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

    public func removeFeatureImage() throws -> EditorPostSettings {
        currentFeaturedImage.tap()

        try FeaturedImageScreen()
            .tapRemoveFeaturedImageButton()

        return try EditorPostSettings()
    }

    public func setFeaturedImage() throws -> EditorPostSettings {
        featuredImageButton.tap()
        try MediaPickerAlbumListScreen()
            .selectAlbum(atIndex: 0) // Select media library
            .selectImage(atIndex: 0) // Select latest uploaded image

        return try EditorPostSettings()
    }

    public func verifyPostSettings(withCategory category: String? = nil, withTag tag: String? = nil, hasImage: Bool) throws -> EditorPostSettings {
        if let postCategory = category {
            XCTAssertTrue(categoriesSection.staticTexts[postCategory].exists, "Category \(postCategory) not set")
        }
        if let postTag = tag {
            XCTAssertTrue(tagsSection.staticTexts[postTag].exists, "Tag \(postTag) not set")
        }
        if hasImage {
            XCTAssertTrue(currentFeaturedImage.exists, "Featured image not set")
        } else {
            XCTAssertFalse(currentFeaturedImage.exists, "Featured image is set but should not be")
        }

        return try EditorPostSettings()
    }

    @discardableResult
    public func closePostSettings() throws -> BlockEditorScreen {
        navigateBack()

        return try BlockEditorScreen()
    }

    public static func isLoaded() -> Bool {
        return (try? EditorPostSettings().isLoaded) ?? false
    }

    @discardableResult
    public func updatePublishDateToFutureDate() -> Self {
        publishDateButton.tap()
        dateSelector.tap()

        // Selects the first day of the next month
        nextMonthButton.tap()
        firstCalendarDayLabel.tap()

        doneButton.tap()
        return self
    }

    public func closePublishDateSelector() -> Self {
        navigateBack()
        return self
    }
}
