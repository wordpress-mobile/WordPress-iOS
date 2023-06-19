import ScreenObject
import XCTest

public class PeopleScreen: ScreenObject {

    public init(app: XCUIApplication = XCUIApplication()) throws {
        let filterButtonGetter: (String) -> (XCUIApplication) -> XCUIElement = { identifier in
            return { app in
                app.buttons[identifier]
            }
        }

        try super.init(
            expectedElementGetters: [
                // See the PeopleViewController.Filter rawValues
                filterButtonGetter("users"),
                filterButtonGetter("followers"),
                filterButtonGetter("email")
            ],
            app: app,
            waitTimeout: 7
        )
    }

    public func verifyPeopleScreenLoaded() {
        XCTAssertTrue(isLoaded)
    }

    public static func isLoaded() -> Bool {
        (try? PeopleScreen().isLoaded) ?? false
    }
}
