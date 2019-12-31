import Foundation
import XCTest

class FancyAlertComponent: BaseScreen {
    let defaultAlertButton: XCUIElement
    let cancelAlertButton: XCUIElement

    struct ElementIDs {
        static let defaultButton = "fancy-alert-view-default-button"
        static let cancelButton = "fancy-alert-view-cancel-button"
    }

    init() {
        defaultAlertButton = XCUIApplication().buttons[ElementIDs.defaultButton]
        cancelAlertButton = XCUIApplication().buttons[ElementIDs.cancelButton]

        super.init(element: defaultAlertButton)
    }

    func acceptAlert() {
        defaultAlertButton.tap()
    }

    func cancelAlert() {
        cancelAlertButton.tap()
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().buttons[ElementIDs.defaultButton].waitForExistence(timeout: 3)
    }
}
