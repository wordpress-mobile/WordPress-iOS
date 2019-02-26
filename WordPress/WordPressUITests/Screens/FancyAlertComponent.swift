import Foundation
import XCTest

class FancyAlertComponent: BaseScreen {
    let defaultAlertButton: XCUIElement
    let cancelAlertButton: XCUIElement

    init() {
        defaultAlertButton = XCUIApplication().buttons["defaultAlertButton"]
        cancelAlertButton = XCUIApplication().buttons["cancelAlertButton"]

        super.init(element: defaultAlertButton)
    }

    func acceptAlert() {
        defaultAlertButton.tap()
    }

    func cancelAlert() {
        cancelAlertButton.tap()
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().buttons["defaultAlertButton"].exists
    }
}
