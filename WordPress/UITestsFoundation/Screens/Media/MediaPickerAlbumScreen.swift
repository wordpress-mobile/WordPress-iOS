import ScreenObject
import XCTest

public class MediaPickerAlbumScreen: ScreenObject {

    private let mediaCollectionGetter: (XCUIApplication) -> XCUIElement = {
        $0.collectionViews["MediaCollection"]
    }

    private let selectedActionButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["SelectedActionButton"]
    }

    private let azctecEditorNavigationBarGetter: (XCUIApplication) -> XCUIElement = {
        $0.navigationBars["Azctec Editor Navigation Bar"]
    }

    var azctecEditorNavigationBar: XCUIElement { azctecEditorNavigationBarGetter(app) }
    var mediaCollection: XCUIElement { mediaCollectionGetter(app) }
    var selectedActionButton: XCUIElement { selectedActionButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [mediaCollectionGetter],
            app: app
        )
    }

    public func selectImage(atIndex index: Int) {
        let selectedImage = mediaCollection.cells.element(boundBy: index)
        XCTAssertTrue(selectedImage.waitForExistence(timeout: 5), "Selected image did not load")
        selectedImage.tap()
    }

    public func selectMultipleImages(_ numberOfImages: Int) {
        var index = 0
        while index < numberOfImages {
            selectImage(atIndex: index)
            index += 1
        }

        selectedActionButton.tap()
    }

    public static func isLoaded(app: XCUIApplication = XCUIApplication()) -> Bool {
        return (try? MediaPickerAlbumScreen().isLoaded) ?? false
    }
}
