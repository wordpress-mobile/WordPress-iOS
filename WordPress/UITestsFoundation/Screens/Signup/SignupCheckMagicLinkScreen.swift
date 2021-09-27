import ScreenObject
import XCTest

public class SignupCheckMagicLinkScreen: ScreenObject {

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [{ $0.buttons["Open Mail Button"] }],
            app: app
        )
    }

    public func openMagicSignupLink() -> SignupEpilogueScreen {
        openMagicLink()

        return SignupEpilogueScreen()
    }
}
