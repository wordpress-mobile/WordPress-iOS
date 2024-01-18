import ScreenObject
import XCTest

public class DomainResultScreen: ScreenObject {
    private let domainResultDoneButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Done"]
    }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ domainResultDoneButtonGetter ],
            app: app,
            waitTimeout: 7
        )
    }

    public static func isLoaded() -> Bool {
        (try? DomainResultScreen().isLoaded) ?? false
    }

    @discardableResult
    public func verifyDomainResultScreenLoaded() -> Self {
        XCTAssertTrue(DomainResultScreen.isLoaded(), "\"Domain Result\" screen isn't loaded.")
        return self
    }

    @discardableResult
    public func dismissResultScreen() throws -> MySiteScreen {
        domainResultDoneButtonGetter(app).tap()
        return try MySiteScreen()
    }
}
