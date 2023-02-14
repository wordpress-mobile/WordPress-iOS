import ScreenObject
import XCTest

public class PeopleScreen: ScreenObject {

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                // See the PeopleViewController.Filter rawValues
                { $0.buttons["users"] },
                { $0.buttons["followers"] },
                { $0.buttons["email"] },
            ],
            app: app,
            waitTimeout: 7
        )
    }

    public static func isLoaded() -> Bool {
        (try? PeopleScreen().isLoaded) ?? false
    }
}
