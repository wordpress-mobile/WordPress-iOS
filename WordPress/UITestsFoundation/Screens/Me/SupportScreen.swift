import ScreenObject
import XCTest

/// This screen object is for the Support section. In the app, it's a modal we can get to from Me 
/// > Help & Support, or, when logged out, from Prologue > tap either continue button > Help.
public class SupportScreen: ScreenObject {

    private let closeButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["close-button"]
    }

    private let contactSupportButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["contact-support-button"]
    }

    private let contactEmailFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.textFields["Email"]
    }

    private let okButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["OK"]
    }

    var closeButton: XCUIElement { closeButtonGetter(app) }
    var contactSupportButton: XCUIElement { contactSupportButtonGetter(app) }
    var contactEmailField: XCUIElement { contactEmailFieldGetter(app) }
    var okButton: XCUIElement { okButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                closeButtonGetter,
                contactSupportButtonGetter,
                // swiftlint:disable opening_brace
                { $0.cells["help-center-link-button"] },
                { $0.cells["my-tickets-button"] },
                { $0.cells["set-contact-email-button"] },
                { $0.cells["activity-logs-button"] }
                // swiftlint:enable opening_brace
            ],
            app: app
        )
    }

    public func contactSupport() throws -> ContactUsScreen {
        contactSupportButton.tap()
        addContactInformationIfNeeded()
        return try ContactUsScreen()
    }

    private func addContactInformationIfNeeded() {
        if contactEmailField.waitForExistence(timeout: 3) {
            contactEmailField.tap()
            contactEmailField.typeText("user@test.zzz")
            okButton.tap()
        }
    }

    public func dismiss() {
        closeButton.tap()
    }

    static func isLoaded() -> Bool {
        (try? SupportScreen().isLoaded) ?? false
    }
}
