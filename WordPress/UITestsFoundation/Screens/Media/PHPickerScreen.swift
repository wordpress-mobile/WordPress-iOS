import ScreenObject
import XCTest

public class PHPickerScreen: ScreenObject {

    private let addButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Add"]
    }

    private let photosNavigationBarGetter: (XCUIApplication) -> XCUIElement = {
        $0.navigationBars["Photos"]
    }

    private let photosScrollViewGetter: (XCUIApplication) -> XCUIElement = {
        $0.otherElements["Photos"].scrollViews.firstMatch
    }

    var addButton: XCUIElement { addButtonGetter(app) }
    var photosNavigationBar: XCUIElement { photosNavigationBarGetter(app) }
    var photosScrollView: XCUIElement { photosScrollViewGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetter: photosNavigationBarGetter,
            app: app
        )
    }

    public func selectImage(atIndex index: Int) {
        let selectedImage = photosScrollView.images.element(boundBy: index)
        XCTAssertTrue(selectedImage.waitForExistence(timeout: 5), "Selected image did not load")
        selectedImage.tap()
    }

    public func selectMultipleImages(_ numberOfImages: Int) {
        var index = 0
        while index < numberOfImages {
            selectImage(atIndex: index)
            index += 1
        }

        addButton.tap()
    }

    public static func isLoaded(app: XCUIApplication = XCUIApplication()) -> Bool {
        return (try? PHPickerScreen().isLoaded) ?? false
    }
}
