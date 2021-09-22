import XCTest

public class FeaturedImageScreen: BaseScreen {

    let removeButton: XCUIElement

    public init() {
        let app = XCUIApplication()
        removeButton = app.navigationBars.buttons["Remove Featured Image"]
        super.init(element: removeButton )
    }

    public func tapRemoveFeaturedImageButton() {
        removeButton.tap()
        app.sheets.buttons.element(boundBy: 0).tap()
    }

}
