import XCTest

public class FancyAlertComponent: BaseScreen {
    let defaultAlertButton: XCUIElement
    let cancelAlertButton: XCUIElement

    public enum Action {
        case accept
        case cancel
    }

    struct ElementIDs {
        static let defaultButton = "fancy-alert-view-default-button"
        static let cancelButton = "fancy-alert-view-cancel-button"
    }

    public init() {
        defaultAlertButton = XCUIApplication().buttons[ElementIDs.defaultButton]
        cancelAlertButton = XCUIApplication().buttons[ElementIDs.cancelButton]

        super.init(element: defaultAlertButton)
    }

    public func acceptAlert() {
        XCTAssert(defaultAlertButton.waitForExistence(timeout: 3))
        XCTAssert(defaultAlertButton.waitForHittability(timeout: 3))

        XCTAssert(defaultAlertButton.isHittable)
        defaultAlertButton.tap()
    }

    func cancelAlert() {
        cancelAlertButton.tap()
    }

    public static func isLoaded() -> Bool {
        return XCUIApplication().buttons[ElementIDs.defaultButton].waitForExistence(timeout: 3)
    }
}
