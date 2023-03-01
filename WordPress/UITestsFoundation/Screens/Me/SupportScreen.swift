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

    private let visitForumsButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["visit-wordpress-forums-button"]
    }

    private let okButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["OK"]
    }

    var closeButton: XCUIElement { closeButtonGetter(app) }
    var visitForumsButton: XCUIElement { visitForumsButtonGetter(app) }
    var okButton: XCUIElement { okButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                closeButtonGetter,
                visitForumsButtonGetter,
                // swiftlint:disable opening_brace
                { $0.cells["visit-wordpress-forums-prompt"] },
                { $0.cells["activity-logs-button"] }
                // swiftlint:enable opening_brace
            ],
            app: app,
            waitTimeout: 7
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
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
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
