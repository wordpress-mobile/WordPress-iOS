import XCTest

public class JetpackBackupOptionsScreen: BaseScreen {

    public init() {
        super.init(element: XCUIApplication().otherElements.firstMatch)
    }
}
