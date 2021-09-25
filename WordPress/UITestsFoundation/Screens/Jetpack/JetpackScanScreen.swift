import XCTest

public class JetpackScanScreen: BaseScreen {

    public init() {
        super.init(element: XCUIApplication().otherElements.firstMatch)
    }
}
