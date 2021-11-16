import ScreenObject
import XCTest
import XCUITestHelpers

public class FancyAlertComponent: ScreenObject {

    private let defaultAlertButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["fancy-alert-view-default-button"]
    }

    private let cancelAlertButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["fancy-alert-view-cancel-button"]
    }

    var defaultAlertButton: XCUIElement { defaultAlertButtonGetter(app) }
    var cancelAlertButton: XCUIElement { cancelAlertButtonGetter(app) }

    public enum Action {
        case accept
        case cancel
    }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [defaultAlertButtonGetter, cancelAlertButtonGetter],
            app: app,
            waitTimeout: 3
        )
    }

    public func acceptAlert() {
        XCTAssert(defaultAlertButton.waitForExistence(timeout: 3))
        XCTAssert(defaultAlertButton.waitForIsHittable(timeout: 3))

        XCTAssert(defaultAlertButton.isHittable)
        defaultAlertButton.tap()
    }

    public func cancelAlert() {
        cancelAlertButton.tap()
    }

    public static func isLoaded() -> Bool {
        (try? FancyAlertComponent().isLoaded) ?? false
    }
}
