import XCTest

var isIPhone: Bool {
    return UIDevice.current.userInterfaceIdiom == .phone
}

var isIpad: Bool {
    return UIDevice.current.userInterfaceIdiom == .pad
}

let navBackButton = XCUIApplication().navigationBars.element(boundBy: 0).buttons.element(boundBy: 0)

extension XCUIElement {
    /**
     Removes any current text in the field
     */
    func clearTextIfNeeded() -> Void {
        let app = XCUIApplication()

        self.press(forDuration: 1.2)
        app.keys["delete"].tap()
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

    var stringValue: String? {
        return self.value as? String
    }
}

extension XCTestCase {

    public func setUpTestSuite() {
        super.setUp()

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        let app = XCUIApplication()
        app.launchArguments = ["-wpcom-api-base-url", WireMock.URL().absoluteString, "-no-animations"]
        app.activate()

        // Media permissions alert handler
        systemAlertHandler(alertTitle: "“WordPress” Would Like to Access Your Photos", alertButton: "OK")
    }

    public func takeScreenshotOfFailedTest() {
        if let failureCount = testRun?.failureCount, failureCount > 0 {
            XCTContext.runActivity(named: "Take a screenshot at the end of a failed test") { (activity) in
                add(XCTAttachment(screenshot: XCUIApplication().windows.firstMatch.screenshot()))
            }
        }
    }

    public func systemAlertHandler(alertTitle: String, alertButton: String) {
        addUIInterruptionMonitor(withDescription: alertTitle) { (alert) -> Bool in
            let alertButtonElement = alert.buttons[alertButton]
            self.waitForElementToExist(element: alertButtonElement)
            alertButtonElement.tap()
            return true
        }
    }

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

    public func getRandomPhrase() -> String {
        var wordArray: [String] = []
        let phraseLength = Int.random(in: 3...6)
        for _ in 1...phraseLength {
            wordArray.append(DataHelper.words.randomElement()!)
        }
        let phrase = wordArray.joined(separator: " ")

        return phrase
    }

    public func getRandomContent() -> String {
        var sentenceArray: [String] = []
        let paraLength = Int.random(in: 1...DataHelper.sentences.count)
        for _ in 1...paraLength {
            sentenceArray.append(DataHelper.sentences.randomElement()!)
        }
        let paragraph = sentenceArray.joined(separator: " ")

        return paragraph
    }

    public func getCategory() -> String {
        return "iOS Test"
    }

    public func getTag() -> String {
        return "tag \(Date().toString())"
    }

    public struct DataHelper {
        static let words = ["Lorem", "Ipsum", "Dolor", "Sit", "Amet", "Consectetur", "Adipiscing", "Elit"]
        static let sentences = ["Lorem ipsum dolor sit amet, consectetur adipiscing elit.", "Nam ornare accumsan ante, sollicitudin bibendum erat bibendum nec.", "Nam congue efficitur leo eget porta.", "Proin dictum non ligula aliquam varius.", "Aenean vehicula nunc in sapien rutrum, nec vehicula enim iaculis."]
        static let category = "iOS Test"
        static let tag = "tag \(Date().toString())"
    }
}
