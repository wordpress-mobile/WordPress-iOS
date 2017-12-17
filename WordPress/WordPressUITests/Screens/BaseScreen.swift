import Foundation
import XCTest

class BaseScreen {
    var app: XCUIApplication!
    var expectedElement: XCUIElement!
    var waitTimeout: Double!
    var testCase: XCTestCase

    init(element: XCUIElement) {
        testCase = XCTestCase.init()

        app = XCUIApplication()
        expectedElement = element
        waitTimeout = 20
        _ = waitForPage()
    }

    func waitForPage() -> BaseScreen {
        _ = expectedElement.waitForExistence(timeout: waitTimeout)
        Logger.log(message: "Page \(self) is loaded", event: .i)
        return self
    }

    // predicate: "isEnabled == true"
    func waitFor(predicate: String, element: XCUIElement, timeout: Int? = 5) {
        let pred = NSPredicate(format: predicate)
        testCase.expectation(for: pred, evaluatedWith: element, handler: nil)
        testCase.waitForExpectations(timeout: TimeInterval(timeout!), handler: nil)
    }

    func isLoaded() -> Bool {
        return expectedElement.exists
    }
}
