import ScreenObject
import XCTest

public class EditorPostSettings: ScreenObject {

    // expectedElement comes from the superclass and gets the first expectedElementGetters result
    var settingsTable: XCUIElement { expectedElement }

    var categoriesSection: XCUIElement { settingsTable.cells["Categories"] }
    var tagsSection: XCUIElement { settingsTable.cells["Tags"] }
    var featuredImageButton: XCUIElement { settingsTable.cells["SetFeaturedImage"] }
    var changeFeaturedImageButton: XCUIElement { settingsTable.cells["CurrentFeaturedImage"] }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ { $0.tables["SettingsTable"] } ],
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
        changeFeaturedImageButton.tap()

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
        let imageCount = settingsTable.images.count
        if hasImage {
            XCTAssertTrue(imageCount == 1, "Featured image not set")
        } else {
            XCTAssertTrue(imageCount == 0, "Featured image is set but should not be")
        }

        return try EditorPostSettings()
    }

    /// - Note: Returns `Void` because the return screen depends on which editor the user is in.
    public func closePostSettings() {
        navBackButton.tap()
    }

    public static func isLoaded() -> Bool {
        return (try? EditorPostSettings().isLoaded) ?? false
    }
}
