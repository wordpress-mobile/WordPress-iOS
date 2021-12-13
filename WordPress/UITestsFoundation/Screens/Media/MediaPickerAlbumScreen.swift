import ScreenObject
import XCTest

public class MediaPickerAlbumScreen: ScreenObject {
    let mediaCollectionGetter: (XCUIApplication) -> XCUIElement = {
        $0.collectionViews["MediaCollection"]
    }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(expectedElementGetters: [mediaCollectionGetter], app: app)
    }

    public func selectImage(atIndex index: Int) {
        let selectedImage = mediaCollectionGetter(app).cells.element(boundBy: index)
        XCTAssertTrue(selectedImage.waitForExistence(timeout: 5), "Selected image did not load")
        selectedImage.tap()
    }

    func insertSelectedImage() {
        app.buttons["SelectedActionButton"].tap()
    }

    public static func isLoaded(app: XCUIApplication = XCUIApplication()) -> Bool {
        // Check if the media picker is loaded as a component within the editor
        // and only return true if the media picker is a full screen
        if app.navigationBars["Azctec Editor Navigation Bar"].exists {
            return false
        }

        return (try? MediaPickerAlbumScreen().isLoaded) ?? false
    }
}
