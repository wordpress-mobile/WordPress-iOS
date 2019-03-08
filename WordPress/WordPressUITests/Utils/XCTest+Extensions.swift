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

extension XCTest {

    func isIPhone() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
}

func isIpad() -> Bool {
    debugPrint(UIDevice.current.userInterfaceIdiom)
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

    public func elementIsFullyVisibleOnScreen(element: XCUIElement) -> Bool {
        guard element.exists && !element.frame.isEmpty && element.isHittable else { return false }
        return XCUIApplication().windows.element(boundBy: 0).frame.contains(element.frame)
    }

    /// Scroll an element into view within another element.
    /// scrollView can be a UIScrollView, or anything that subclasses it like UITableView
    ///
    /// TODO: The implementation of this could use work:
    /// - What happens if the element is above the current scroll view position?
    /// - What happens if it's a really long scroll view?

    public func scrollElementIntoView(element: XCUIElement, within scrollView: XCUIElement, threshold: Int = 1000) {

        var iteration = 0

        while !elementIsFullyVisibleOnScreen(element: element) && iteration < threshold {
            scrollView.swipeUp()
            iteration += 1
        }

        if !elementIsFullyVisibleOnScreen(element: element) {
            XCTFail("Unable to scroll element into view")
        }
    }
}
