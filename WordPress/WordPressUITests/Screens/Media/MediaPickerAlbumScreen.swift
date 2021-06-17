import UITestsFoundation
import XCTest

class MediaPickerAlbumScreen: BaseScreen {
    let mediaCollection: XCUIElement
    let insertButton: XCUIElement

    init() {
        let app = XCUIApplication()
        mediaCollection = app.collectionViews["MediaCollection"]
        insertButton = app.buttons["SelectedActionButton"]

        super.init(element: mediaCollection)
    }

    func selectImage(atIndex index: Int) {
        let selectedImage = mediaCollection.cells.element(boundBy: index)
        XCTAssertTrue(selectedImage.waitForExistence(timeout: 5), "Selected image did not load")
        selectedImage.tap()
    }

    func insertSelectedImage() {
        insertButton.tap()
    }

    static func isLoaded() -> Bool {
        // Check if the media picker is loaded as a component within the editor
        // and only return true if the media picker is a full screen
        if XCUIApplication().navigationBars["Azctec Editor Navigation Bar"].exists {
            return false
        }

        return XCUIApplication().collectionViews["MediaCollection"].exists
    }
}
