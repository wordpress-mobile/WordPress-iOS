import UITestsFoundation
import XCTest

extension XCTestCase {

    public func setUpTestSuite(for appName: String? = nil, app: XCUIApplication = XCUIApplication()) {
        super.setUp()

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        app.launchArguments = ["-wpcom-api-base-url", WireMock.URL().absoluteString, "-no-animations", "-ui-testing"]

        if let appName = appName {
            removeApp(appName)
        }

        app.activate()

        // Media permissions alert handler
        let alertButtonTitle: String
        if #available(iOS 14.0, *) {
            alertButtonTitle = "Allow Access to All Photos"
        } else {
            alertButtonTitle = "OK"
        }
        systemAlertHandler(alertTitle: "“WordPress” Would Like to Access Your Photos", alertButton: alertButtonTitle)
    }

    public func takeScreenshotOfFailedTest() {
        guard let failuresCount = testRun?.failureCount, failuresCount > 0 else { return }

        XCTContext.runActivity(named: "Take a screenshot at the end of a failed test") { activity in
            add(XCTAttachment(screenshot: XCUIApplication().windows.firstMatch.screenshot()))
        }
    }

    public func systemAlertHandler(alertTitle: String, alertButton: String) {
        addUIInterruptionMonitor(withDescription: alertTitle) { (alert) -> Bool in
            let alertButtonElement = alert.buttons[alertButton]
            XCTAssert(alertButtonElement.waitForExistence(timeout: 5))
            alertButtonElement.tap()
            return true
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
        return "Wedding"
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

    public func removeApp(_ appName: String = "WordPress", app: XCUIApplication = XCUIApplication()) {
        app.terminate()

        let appToRemove = Constants.homeApp.icons[appName]
        if appToRemove.exists {
            appToRemove.firstMatch.press(forDuration: 1)
            waitAndTap(Constants.homeApp.buttons["Remove App"])
            waitAndTap(Constants.homeApp.alerts.buttons["Delete App"])
            waitAndTap(Constants.homeApp.alerts.buttons["Delete"])
        }
    }

    public func waitAndTap( _ element: XCUIElement) {
        var retries = 0
        let maxRetries = 10
        if element.waitForIsHittable(timeout: 10) {
            while element.isHittable && retries < maxRetries {
                element.tap()
                retries += 1
            }
        }
    }

    private enum Constants {
        static let homeApp = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    }
}
