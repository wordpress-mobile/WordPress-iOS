import XCTest

public class ActivityLogScreen: BaseScreen {

    public init() {
        super.init(element: XCUIApplication().otherElements.firstMatch)
    }
}
