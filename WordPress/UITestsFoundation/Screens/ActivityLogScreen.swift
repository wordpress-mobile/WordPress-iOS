import ScreenObject
import XCTest

public class ActivityLogScreen: ScreenObject {
    public let tabBar: TabNavComponent

    let dateRangeButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Date Range"].firstMatch
    }

    let activityTypeButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Activity Type"].firstMatch
    }

    var dateRangeButton: XCUIElement { dateRangeButtonGetter(app) }
    var activityTypeButton: XCUIElement { activityTypeButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        tabBar = try TabNavComponent()

        try super.init(
            expectedElementGetters: [ dateRangeButtonGetter, activityTypeButtonGetter ],
            app: app,
            waitTimeout: 7
        )
    }

    public static func isLoaded() -> Bool {
        (try? ActivityLogScreen().isLoaded) ?? false
    }

    @discardableResult
    public func verifyActivityLogScreenLoaded() -> Self {
        XCTAssertTrue(ActivityLogScreen.isLoaded(), "\"Activity\" screen isn't loaded.")
        return self
    }

    @discardableResult
    public func verifyActivityLogScreen(hasActivityPartial activityTitle: String) -> Self {
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", activityTitle)).firstMatch.waitForIsHittable(),
            "Activity Log Screen: \"\(activityTitle)\" activity not displayed.")
        return self
    }
}
