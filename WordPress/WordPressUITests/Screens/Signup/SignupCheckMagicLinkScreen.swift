import Foundation
import XCTest

private struct ElementStringIDs {
    static let mailButton = "Open Mail Button"
}

class SignupCheckMagicLinkScreen: BaseScreen {
    let mailButton: XCUIElement

    init() {
        let app = XCUIApplication()
        mailButton = app.buttons[ElementStringIDs.mailButton]

        super.init(element: mailButton)
    }

    func openMagicSignupLink() -> SignupEpilogueScreen {
        openMagicLink()

        return SignupEpilogueScreen()
    }
}
