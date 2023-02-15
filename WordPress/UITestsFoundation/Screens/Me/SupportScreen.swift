import ScreenObject
import XCTest

/// This screen object is for the Support section. In the app, it's a modal we can get to from Me
/// > Help & Support, or, when logged out, from Prologue > tap either continue button > Help.
public class SupportScreen: ScreenObject {

    private let closeButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["close-button"]
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
            waitTimeout: 22
        )
    }

    public func assertVisitForumButtonEnabled() -> SupportScreen {
        XCTAssert(visitForumsButton.isEnabled)
        return self
    }

    public func visitForums() {
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        visitForumsButton.tap()

        // Select the Address bar when Safari opens
        let addressBar = safari.textFields["Address"]
        guard addressBar.waitForExistence(timeout: 5) else {
            XCTFail("Address bar not found")
            return
        }
        addressBar.tap()

        guard safari.wait(for: .runningForeground, timeout: 4) else {
            XCTFail("Safari wait failed")
            return
        }

        XCTAssertEqual(addressBar.value as! String, "https://wordpress.org/support/forum/mobile/")
        app.activate() //Back to app
    }

    public func dismiss() {
        closeButton.tap()
    }

    static func isLoaded() -> Bool {
        (try? SupportScreen().isLoaded) ?? false
    }
}
