import UITestsFoundation
import XCTest

extension XCTestCase {

    // Require main actor isolation because of the calls to app.terminate() and app.activate()
    // which require running on the main thread.
    @MainActor
    public func setUpTestSuite(
        for app: XCUIApplication = XCUIApplication(),
        removeBeforeLaunching: Bool = false,
        crashOnCoreDataConcurrencyIssues: Bool = true,
        selectWPComSite: String? = nil
    ) {
        // To ensure that the test starts with a new simulator launch each time
        app.terminate()
        super.setUp()

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        app.launchArguments = ["-wpcom-api-base-url", WireMock.URL().absoluteString, "-no-animations", "-ui-testing", "-logout-at-launch"]

        if crashOnCoreDataConcurrencyIssues {
            app.launchArguments.append(contentsOf: ["-com.apple.CoreData.ConcurrencyDebug", "1"])
        }

        if let selectWPComSite {
            app.launchArguments.append(contentsOf: ["-ui-test-select-wpcom-site", selectWPComSite])
        }

        if removeBeforeLaunching {
            removeApp(app)
        }

        app.activate()

        // Media permissions alert handler
        let alertButtonTitle = "Allow Access to All Photos"
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
}
