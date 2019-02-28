import XCTest

extension XCUIElement {
    /**
     Removes any current text in the field
     */
    func clearTextIfNeeded() -> Void {
        let app = XCUIApplication()
        let content = self.value as! String

        if content.count > 0 && content != self.placeholderValue {
            self.press(forDuration: 1.2)
            app.menuItems["Select All"].tap()
            app.menuItems["Cut"].tap()
        }
    }

    /**
     Removes any current text in the field before typing in the new value
     - Parameter text: the text to enter into the field
     */
    func clearAndEnterText(text: String) -> Void {
        clearTextIfNeeded()
        self.tap()
        self.typeText(text)
    }
}

var isIPhone: Bool {
    return UIDevice.current.userInterfaceIdiom == .phone
}

var isIpad: Bool {
    return UIDevice.current.userInterfaceIdiom == .pad
}

extension XCTestCase {

    public func waitForElementToExist(element: XCUIElement, timeout: TimeInterval? = nil) {
        let timeoutValue = timeout ?? 30
        guard element.waitForExistence(timeout: timeoutValue) else {
            XCTFail("Failed to find \(element) after \(timeoutValue) seconds.")
            return
        }
    }

    public func waitForElementToNotExist(element: XCUIElement, timeout: TimeInterval? = nil) {
        let notExistsPredicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: notExistsPredicate,
                                                    object: element)

        let timeoutValue = timeout ?? 30
        guard XCTWaiter().wait(for: [expectation], timeout: timeoutValue) == .completed else {
            XCTFail("\(element) still exists after \(timeoutValue) seconds.")
            return
        }
    }
}
