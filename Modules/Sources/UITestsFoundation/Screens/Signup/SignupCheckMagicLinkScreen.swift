import ScreenObject
import XCTest

public class SignupCheckMagicLinkScreen: ScreenObject {

    private let openMailButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Open Mail Button"]
    }

    var openMailButton: XCUIElement { openMailButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [openMailButtonGetter],
            app: app
        )
    }

    public func openMagicSignupLink() throws -> SignupEpilogueScreen {
        openMagicLink()

        return try SignupEpilogueScreen()
    }
}
