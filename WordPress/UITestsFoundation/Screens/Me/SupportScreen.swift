import ScreenObject
import XCTest

/// This screen object is for the Support section. In the app, it's a modal we can get to from Me 
/// > Help & Support, or, when logged out, from Prologue > tap either continue button > Help.
public class SupportScreen: ScreenObject {

    private let closeButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["close-button"]
    }

    var closeButton: XCUIElement { closeButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                closeButtonGetter,
                // swiftlint:disable opening_brace
                { $0.cells["help-center-link-button"] },
                { $0.cells["contact-support-button"] },
                { $0.cells["my-tickets-button"] },
                { $0.cells["set-contact-email-button"] },
                { $0.cells["activity-logs-button"] }
                // swiftlint:enable opening_brace
            ],
            app: app
        )
    }

    public func contactSupport() throws -> ContactUsScreen {
        app.cells["contact-support-button"].tap()
        addContactInformationIfNeeded()
        return try ContactUsScreen()
    }

    private func addContactInformationIfNeeded() {
        let emailTextField = app.textFields["Email"]
        if emailTextField.waitForExistence(timeout: 3) {
            emailTextField.tap()
            emailTextField.typeText("user@test.zzz")
            app.buttons["OK"].tap()
        }
    }

    public func dismiss() {
        closeButton.tap()
    }

    static func isLoaded() -> Bool {
        (try? SupportScreen().isLoaded) ?? false
    }
}
