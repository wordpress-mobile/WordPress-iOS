import ScreenObject
import XCTest

public class FeaturedImageScreen: ScreenObject {

    // expectedElement comes from the superclass and gets the first expectedElementGetters result
    var removeButton: XCUIElement { expectedElement }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ { $0.navigationBars.buttons["Remove Featured Image"] } ],
            app: app
        )
    }

    public func tapRemoveFeaturedImageButton() {
        removeButton.tap()
        app.sheets.buttons.element(boundBy: 0).tap()
    }

}
