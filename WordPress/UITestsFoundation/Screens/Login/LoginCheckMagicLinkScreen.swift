import ScreenObject
import XCTest

public class LoginCheckMagicLinkScreen: ScreenObject {

    let passwordOptionGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Use Password"]
    }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                passwordOptionGetter,
                // swiftlint:disable:next opening_brace
                { $0.buttons["Open Mail Button"] }
            ],
            app: app
        )
    }

    func proceedWithPassword() throws -> LoginPasswordScreen {
        passwordOptionGetter(app).tap()

        return try LoginPasswordScreen()
    }

    public func openMagicLoginLink() throws -> LoginEpilogueScreen {
        openMagicLink()

        return try LoginEpilogueScreen()
    }

    public static func isLoaded() -> Bool {
        (try? LoginCheckMagicLinkScreen().isLoaded) ?? false
    }
}
