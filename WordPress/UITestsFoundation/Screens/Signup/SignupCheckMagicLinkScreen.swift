import ScreenObject
import XCTest

public class SignupCheckMagicLinkScreen: ScreenObject {

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            // swiftlint:disable:next opening_brace
            expectedElementGetters: [{ $0.buttons["Open Mail Button"] }],
            app: app
        )
    }

    public func openMagicSignupLink() throws -> SignupEpilogueScreen {
        openMagicLink()

        return try SignupEpilogueScreen()
    }
}
