import ScreenObject
import XCTest

/// This screen object is for the Support section. In the app, it's a modal we can get to from Me
/// > Help & Support > Contact Support, or, when logged out, from Prologue > tap either continue button > Help > Contact Support.
public class ContactUsScreen: ScreenObject {

    private let closeButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["ZDKbackButton"]
    }

    private let sendButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["ZDKsendButton"]
    }

    private let attachButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["ZDKattachButton"]
    }

    var closeButton: XCUIElement { closeButtonGetter(app) }
    var sendButton: XCUIElement { sendButtonGetter(app) }
    var attachButton: XCUIElement { attachButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        // Notice we are not checking for the send button because it's visible but not enabled,
        // and `ScreenObject` checks for enabled elements.
        try super.init(
            expectedElementGetters: [
                closeButtonGetter,
                attachButtonGetter,
            ],
            app: app
        )
    }

    public func canSendMessage() -> Bool {
        app.typeText("A")
        let isSendButtonEnabled = sendButton.isEnabled
        app.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 1))

        return isSendButtonEnabled
    }

    public func dismiss() throws -> SupportScreen {
        closeButton.tap()
        return try SupportScreen()
    }

    static func isLoaded() -> Bool {
        (try? SupportScreen().isLoaded) ?? false
    }
}
