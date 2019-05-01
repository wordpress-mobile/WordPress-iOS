import Foundation
import XCTest

class EditorPostSettings: BaseScreen {
    let settingsTable: XCUIElement
    let categoriesSection: XCUIElement
    let tagsSection: XCUIElement
    let featuredImageButton: XCUIElement

    init() {
        let app = XCUIApplication()
        settingsTable = app.tables["SettingsTable"]
        categoriesSection = settingsTable.cells["Categories"]
        tagsSection = settingsTable.cells["Tags"]
        featuredImageButton = settingsTable.cells["SetFeaturedImage"]

        super.init(element: settingsTable)
    }

    func openCategories() -> CategoriesComponent {
        categoriesSection.tap()

        return CategoriesComponent()
    }

    func openTags() -> TagsComponent {
        tagsSection.tap()

        return TagsComponent()
    }

    func setFeaturedImage() -> EditorPostSettings {
        featuredImageButton.tap()
        MediaPickerAlbumListScreen()
            .selectAlbum(atIndex: 0) // Select media library
            .selectImage(atIndex: 0) // Select latest uploaded image

        return EditorPostSettings()
    }

    func verifyPostSettings(withCategory category: String? = nil, withTag tag: String? = nil, hasImage: Bool) -> EditorPostSettings {
        if let postCategory = category {
            XCTAssertTrue(categoriesSection.staticTexts[postCategory].exists, "Category \(postCategory) not set")
        }
        if let postTag = tag {
            XCTAssertTrue(tagsSection.staticTexts[postTag].exists, "Tag \(postTag) not set")
        }
        if hasImage {
            let imageCount = settingsTable.images.count
            XCTAssertTrue(imageCount == 1, "Featured image not set")
        }

        return EditorPostSettings()
    }

    func closePostSettings() -> EditorScreen {
        navBackButton.tap()

        return EditorScreen(mode: .rich)
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().tables["SettingsTable"].exists
    }
}
