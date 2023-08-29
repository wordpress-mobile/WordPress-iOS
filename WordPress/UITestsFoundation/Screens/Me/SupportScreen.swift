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

    private let contactEmailTextFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.textFields["Email"]
    }

    private let visitForumsButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["visit-wordpress-forums-button"]
    }

    private let okButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["OK"]
    }

    private let visitWordPressForumsPromptGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["visit-wordpress-forums-prompt"]
    }

    private let activityLogsButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["activity-logs-button"]
    }

    private let contactSupportPlaceholderEmailTextGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["set-contact-email-button"].staticTexts["Not Set"]
    }

    var activityLogsButton: XCUIElement { activityLogsButtonGetter(app) }
    var closeButton: XCUIElement { closeButtonGetter(app) }
    var contactEmailTextField: XCUIElement { contactEmailTextFieldGetter(app) }
    var contactSupportButton: XCUIElement { contactSupportButtonGetter(app) }
    var contactSupportPlaceholderEmailText: XCUIElement { contactSupportPlaceholderEmailTextGetter(app) }
    var okButton: XCUIElement { okButtonGetter(app) }
    var visitForumsButton: XCUIElement { visitForumsButtonGetter(app) }
    var visitWordPressForumsPrompt: XCUIElement { visitWordPressForumsPromptGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                closeButtonGetter,
                visitForumsButtonGetter,
                visitWordPressForumsPromptGetter,
                activityLogsButtonGetter
            ],
            app: app
        )
    }

    public func contactSupport(userEmail: String) throws -> ContactUsScreen {
        let emailExists = contactSupportPlaceholderEmailText.waitForExistence(timeout: 5)
        contactSupportButton.tap()

        // If email exists, skip this
        if emailExists {
            contactEmailTextField.tap()
            contactEmailTextField.typeText(userEmail)
            okButton.tap()
        }

        return try ContactUsScreen()
    }

    public func assertVisitForumButtonEnabled() -> SupportScreen {
        XCTAssert(visitForumsButton.isEnabled)
        return self
    }

    public func visitForums() -> SupportScreen {
        visitForumsButton.tap()

        // Select the Address bar when Safari opens
        let addressBar = findSafariAddressBar(hasBeenTapped: false)

        guard addressBar.waitForExistence(timeout: 5) else {
            XCTFail("Address bar not found")
            return self
        }
        addressBar.tap()

        return self
    }

    public func assertForumsLoaded() {
        let safari = Apps.safari
        guard safari.wait(for: .runningForeground, timeout: 4) else {
            XCTFail("Safari wait failed")
            return
        }

        let addressBar = findSafariAddressBar(hasBeenTapped: true)
        let predicate = NSPredicate(format: "value == 'https://wordpress.org/support/forum/mobile/'")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: addressBar)
        let result = XCTWaiter.wait(for: [expectation], timeout: 5)
        XCTAssertEqual(result, .completed)

        app.activate() //Back to app
    }

    public func dismiss() {
        closeButton.tap()
    }

    static func isLoaded() -> Bool {
        (try? SupportScreen().isLoaded) ?? false
    }
}
