import ScreenObject
import XCTest

public class LoginCheckMagicLinkScreen: ScreenObject {

    private let passwordOptionGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Use Password"]
    }

    private let openMailButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Open Mail Button"]
    }

    var openMailButton: XCUIElement { openMailButtonGetter(app) }
    var passwordOption: XCUIElement { passwordOptionGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                passwordOptionGetter,
                openMailButtonGetter
            ],
            app: app
        )
    }

    func proceedWithPassword() throws -> LoginPasswordScreen {
        passwordOption.tap()

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
