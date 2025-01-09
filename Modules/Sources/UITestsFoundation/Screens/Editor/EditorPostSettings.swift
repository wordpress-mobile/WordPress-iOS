import ScreenObject
import XCTest

public class EditorPostSettings: ScreenObject {

    private let settingsTableGetter: (XCUIApplication) -> XCUIElement = {
        $0.tables["SettingsTable"]
    }

    private let categoriesSectionGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["Categories"]
    }

    private let tagsSectionGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["Tags"]
    }

    private let publishDateButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["Publish Date"]
    }

    private let dateSelectorGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["Immediately"]
    }

    private let nextMonthButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Next Month"]
    }

    private let monthLabelGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Month"]
    }

    private let firstCalendarDayButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons.containing(.staticText, identifier: "1").element
    }

    private let closeButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.navigationBars.buttons["close"]
    }

    private let backButtonGetter: (XCUIApplication) -> XCUIElement? = {
        $0.navigationBars["Publish Date"].buttons.element(boundBy: 0)
    }

    var categoriesSection: XCUIElement { categoriesSectionGetter(app) }
    var chooseFromMediaButton: XCUIElement { app.buttons["Choose from Media"].firstMatch }
    var closeButton: XCUIElement { closeButtonGetter(app) }
    var backButton: XCUIElement? { backButtonGetter(app) }
    var featuredImageCell: XCUIElement { app.cells["post_settings_featured_image_cell"].firstMatch }
    var selectedFeaturedImage: XCUIElement { app.otherElements["featured_image_current_image"].firstMatch }
    var firstCalendarDayButton: XCUIElement { firstCalendarDayButtonGetter(app) }
    var monthLabel: XCUIElement { monthLabelGetter(app) }
    var nextMonthButton: XCUIElement { nextMonthButtonGetter(app) }
    var publishDateButton: XCUIElement { publishDateButtonGetter(app) }
    var settingsTable: XCUIElement { settingsTableGetter(app) }
    var tagsSection: XCUIElement { tagsSectionGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
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
        featuredImageCell.tap()
        app.buttons["featured_image_button_remove"].firstMatch.tap()
        return try EditorPostSettings()
    }

    public func setFeaturedImage() throws -> EditorPostSettings {
        featuredImageCell.tap()
        chooseFromMediaButton.tap()
        try MediaPickerAlbumScreen()
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
            XCTAssertTrue(selectedFeaturedImage.exists, "Featured image not set")
        } else {
            XCTAssertFalse(selectedFeaturedImage.exists, "Featured image is set but should not be")
        }

        return try EditorPostSettings()
    }

    @discardableResult
    public func closePostSettings() throws -> BlockEditorScreen {
        closeButton.tap()

        return try BlockEditorScreen()
    }

    public static func isLoaded() -> Bool {
        return (try? EditorPostSettings().isLoaded) ?? false
    }

    @discardableResult
    public func updatePublishDateToFutureDate() -> Self {
        publishDateButton.tap()
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

    public func closePublishDateSelector() -> Self {
        backButton?.tap()
        return self
    }
}
