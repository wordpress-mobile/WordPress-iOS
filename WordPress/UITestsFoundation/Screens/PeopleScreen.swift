import ScreenObject
import XCTest

public class PeopleScreen: ScreenObject {

    private let emailFilterButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["email"]
    }

    private let followersFilterButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["followers"]
    }

    private let userFilterButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["users"]
    }

    var emailFilterButton: XCUIElement { emailFilterButtonGetter(app) }
    var followersFilterButton: XCUIElement { followersFilterButtonGetter(app) }
    var userFilterButton: XCUIElement { userFilterButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                emailFilterButtonGetter,
                followersFilterButtonGetter,
                userFilterButtonGetter
            ],
            app: app
        )
    }

    public static func isLoaded() -> Bool {
        (try? PeopleScreen().isLoaded) ?? false
    }
}
