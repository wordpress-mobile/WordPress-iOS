import ScreenObject
import XCTest

public class JetpackScanScreen: ScreenObject {

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ { $0.otherElements.firstMatch } ],
            app: app
        )
    }
}
