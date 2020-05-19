import Foundation
import XCTest

class FeaturedImageScreen: BaseScreen {


    let navigationBar: XCUIElement

    init() {
        let app = XCUIApplication()
        navigationBar = app.navigationBars["Featured Image"]
        super.init(element: navigationBar )
    }

    func tapRemoveFeaturedImageButton() {
        navigationBar.buttons["Remove Featured Image"].tap()
        app.sheets["Remove this Featured Image?"].scrollViews.otherElements.buttons["Remove"].tap()
    }

}
