import ScreenObject
import XCTest

public class ActivityLogScreen: ScreenObject {
    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init {
            $0.collectionViews["activity_logs_list"].firstMatch
        }
    }

    @discardableResult
    public func verifyActivityLogScreen(hasActivityPartial activityTitle: String) -> Self {
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", activityTitle)).firstMatch.waitForIsHittable(timeout: 10),
            "Activity Log Screen: \"\(activityTitle)\" activity not displayed.")
        return self
    }
}
