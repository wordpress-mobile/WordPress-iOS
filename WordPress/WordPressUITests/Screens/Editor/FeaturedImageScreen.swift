import Foundation
import XCTest

class FeaturedImageScreen: BaseScreen {


    let removeButton: XCUIElement

    init() {
        let app = XCUIApplication()
        removeButton = app.navigationBars.buttons["Remove Featured Image"]
        super.init(element: removeButton )
    }

    func tapRemoveFeaturedImageButton() {
        removeButton.tap()
        app.sheets.buttons.element(boundBy: 0).tap()
    }

}
