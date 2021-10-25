import ScreenObject
import XCTest

// TODO: remove when unifiedAuth is permanent.

public class LinkOrPasswordScreen: ScreenObject {

    let passwordOptionGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Use Password"]
    }
    let linkButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Send Link Button"]
    }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(expectedElementGetters: [passwordOptionGetter, linkButtonGetter], app: app)
    }

    func proceedWithPassword() throws -> LoginPasswordScreen {
        passwordOptionGetter(app).tap()

        return try LoginPasswordScreen()
    }

    public func proceedWithLink() throws -> LoginCheckMagicLinkScreen {
        linkButtonGetter(app).tap()

        return try LoginCheckMagicLinkScreen()
    }

    public static func isLoaded() -> Bool {
        (try? LinkOrPasswordScreen().isLoaded) ?? false
    }
}
