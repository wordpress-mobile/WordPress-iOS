import ScreenObject
import XCTest

public class ActivityLogScreen: ScreenObject {

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(expectedElementGetters: [ { $0.otherElements.firstMatch } ])
    }
}
