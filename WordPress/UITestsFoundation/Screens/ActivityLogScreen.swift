import ScreenObject
import XCTest

public class ActivityLogScreen: ScreenObject {
    public let tabBar: TabNavComponent

    private let dateRangeButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Date Range"].firstMatch
    }

    private let activityTypeButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Activity Type"].firstMatch
    }

    var activityTypeButton: XCUIElement { activityTypeButtonGetter(app) }
    var dateRangeButton: XCUIElement { dateRangeButtonGetter(app) }

    // Timeout duration to overwrite value defined in XCUITestHelpers
    var duration: TimeInterval = 10.0

    public init(app: XCUIApplication = XCUIApplication()) throws {
        tabBar = try TabNavComponent()

        try super.init(
            expectedElementGetters: [ dateRangeButtonGetter, activityTypeButtonGetter ],
            app: app
        )
    }

    public static func isLoaded() -> Bool {
        (try? ActivityLogScreen().isLoaded) ?? false
    }

    @discardableResult
    public func verifyActivityLogScreen(hasActivityPartial activityTitle: String) -> Self {
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", activityTitle)).firstMatch.waitForIsHittable(timeout: duration),
            "Activity Log Screen: \"\(activityTitle)\" activity not displayed.")
        return self
    }
}
