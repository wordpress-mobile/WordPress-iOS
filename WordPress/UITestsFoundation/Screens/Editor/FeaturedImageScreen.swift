import ScreenObject
import XCTest

public class FeaturedImageScreen: ScreenObject {

    private let removeFeaturedImageButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.navigationBars.buttons["Remove Featured Image"]
    }

    private let removeButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Remove"]
    }

    var removeButton: XCUIElement { removeButtonGetter(app) }
    var removeFeaturedImageButton: XCUIElement { removeFeaturedImageButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ removeFeaturedImageButtonGetter ],
            app: app
        )
    }

    public func tapRemoveFeaturedImageButton() {
        removeFeaturedImageButton.tap()
        removeButton.tap()
    }

}
