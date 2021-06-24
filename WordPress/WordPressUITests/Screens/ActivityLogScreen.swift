import UITestsFoundation
import XCTest

class ActivityLogScreen: BaseScreen {

    init() {
        super.init(element: XCUIApplication().otherElements.firstMatch)
    }
}
