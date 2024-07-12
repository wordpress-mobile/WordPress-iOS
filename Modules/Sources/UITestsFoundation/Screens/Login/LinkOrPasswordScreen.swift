import ScreenObject
import XCTest

public class LinkOrPasswordScreen: ScreenObject {

    private let passwordOptionGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Use Password"]
    }

    private let linkButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Send Link Button"]
    }

    var linkButton: XCUIElement { linkButtonGetter(app) }
    var passwordOption: XCUIElement { passwordOptionGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [passwordOptionGetter, linkButtonGetter],
            app: app
        )
    }

    func proceedWithPassword() throws -> LoginPasswordScreen {
        passwordOption.tap()

        return try LoginPasswordScreen()
    }

    public func proceedWithLink() throws -> LoginCheckMagicLinkScreen {
        linkButton.tap()

        return try LoginCheckMagicLinkScreen()
    }

    public static func isLoaded() -> Bool {
        (try? LinkOrPasswordScreen().isLoaded) ?? false
    }
}
