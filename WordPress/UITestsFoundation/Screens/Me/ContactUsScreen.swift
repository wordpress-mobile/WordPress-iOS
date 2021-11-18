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

    private let messageTextFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.textFields["writeAMessage"]
    }

    var closeButton: XCUIElement { closeButtonGetter(app) }
    var sendButton: XCUIElement { sendButtonGetter(app) }
    var attachButton: XCUIElement { attachButtonGetter(app) }
    var messageTextField: XCUIElement { messageTextFieldGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        // Notice we are not checking for the send button and message text field
        // because they're visible but not enabled, and `ScreenObject` checks for enabled elements.
        try super.init(
            expectedElementGetters: [
                closeButtonGetter,
                attachButtonGetter,
            ],
            app: app
        )
    }

    public func dismiss() throws -> SupportScreen {
        closeButton.tap()
        return try SupportScreen()
    }

    static func isLoaded() -> Bool {
        (try? SupportScreen().isLoaded) ?? false
    }
}
