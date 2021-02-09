import XCTest
import OHHTTPStubs
@testable import WordPress

class AppRatingUtilityTests: XCTestCase {
    fileprivate var defaults: UserDefaults!
    fileprivate var utility: AppRatingUtility!


    override func setUp() {
        let appDomain: String? = Bundle.main.bundleIdentifier
        UserDefaults.standard.removePersistentDomain(forName: appDomain!)
        self.defaults = UserDefaults()
        self.utility = AppRatingUtility(defaults: self.defaults)
        self.utility.setVersion("1.0")
        self.utility.systemWideSignificantEventCountRequiredForPrompt = 1
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testCheckForPromptReturnsFalseWithoutEnoughSignificantEvents() {
        self.utility.systemWideSignificantEventCountRequiredForPrompt = 1
        XCTAssertFalse(self.utility.shouldPromptForAppReview())
    }

    func testCheckForPromptReturnsTrueWithEnoughSignificantEvents() {
        self.utility.systemWideSignificantEventCountRequiredForPrompt = 1
        self.utility.incrementSignificantEvent()
        XCTAssertTrue(self.utility.shouldPromptForAppReview())
    }

    func testCheckForPromptReturnsFalseIfUserHasRatedCurrentVersion() {
        self.createConditionsForPositiveAppReviewPrompt()
        XCTAssertTrue(self.utility.shouldPromptForAppReview())
        self.utility.ratedCurrentVersion()
        XCTAssertFalse(self.utility.shouldPromptForAppReview())
    }

    func testCheckForPromptReturnsFalseIfUserHasGivenFeedbackForCurrentVersion() {
        self.createConditionsForPositiveAppReviewPrompt()
        XCTAssertTrue(self.utility.shouldPromptForAppReview())
        self.utility.gaveFeedbackForCurrentVersion()
        XCTAssertFalse(self.utility.shouldPromptForAppReview())
    }

    func testCheckForPromptReturnsFalseIfUserHasDeclinedToRateCurrentVersion() {
        self.createConditionsForPositiveAppReviewPrompt()
        XCTAssertTrue(self.utility.shouldPromptForAppReview())
        self.utility.declinedToRateCurrentVersion()
        XCTAssertFalse(self.utility.shouldPromptForAppReview())
    }

    func testCheckForPromptShouldResetForNewVersion() {
        self.createConditionsForPositiveAppReviewPrompt()
        XCTAssertTrue(self.utility.shouldPromptForAppReview())
        self.utility.setVersion("2.0")
        XCTAssertFalse(self.utility.shouldPromptForAppReview())
    }

    func testCheckForPromptShouldTriggerWithNewVersion() {
        self.createConditionsForPositiveAppReviewPrompt()
        XCTAssertTrue(self.utility.shouldPromptForAppReview())
        self.utility.setVersion("2.0")
        XCTAssertFalse(self.utility.shouldPromptForAppReview())
        self.createConditionsForPositiveAppReviewPrompt()
        XCTAssertTrue(self.utility.shouldPromptForAppReview())
    }

    func testUserIsNotPromptedForAReviewForOneVersionIfTheyLikedTheApp() {
        self.utility.setVersion("4.7")
        XCTAssertFalse(self.utility.shouldPromptForAppReview())
        self.utility.likedCurrentVersion()

        self.utility.setVersion("4.8")
        self.utility.incrementSignificantEvent()
        XCTAssertFalse(self.utility.shouldPromptForAppReview(), "should not prompt for a review after liking last version")

        self.utility.setVersion("4.9")
        self.utility.incrementSignificantEvent()
        XCTAssertTrue(self.utility.shouldPromptForAppReview(), "should prompt for a review after skipping a version")
    }

    func testUserIsNotPromptedForAReviewForTwoVersionsIfTheyDeclineToRate() {
        self.utility.setVersion("4.7")
        XCTAssertFalse(self.utility.shouldPromptForAppReview())
        self.utility.dislikedCurrentVersion()

        self.utility.setVersion("4.8")
        self.utility.incrementSignificantEvent()
        XCTAssertFalse(self.utility.shouldPromptForAppReview(), "should not prompt for a review after declining on this first upgrade")

        self.utility.setVersion("4.9")
        self.utility.incrementSignificantEvent()
        XCTAssertFalse(self.utility.shouldPromptForAppReview(), "should not prompt for a review after declining on this second upgrade")

        self.utility.setVersion("5.0")
        self.utility.incrementSignificantEvent()
        XCTAssertTrue(self.utility.shouldPromptForAppReview(), "should prompt for a review two versions later")
    }

    func testHasUserEverLikedApp() {
        self.utility.setVersion("4.7")
        XCTAssertFalse(self.utility.hasUserEverLikedApp())
        self.utility.declinedToRateCurrentVersion()

        self.utility.setVersion("4.8")
        XCTAssertFalse(self.utility.hasUserEverLikedApp())
        self.utility.likedCurrentVersion()
        XCTAssertTrue(self.utility.hasUserEverLikedApp())

        self.utility.setVersion("4.9")
        self.utility.dislikedCurrentVersion()
        XCTAssertTrue(self.utility.hasUserEverLikedApp())
    }

    func testHasUserEverDislikedTheApp() {
        self.utility.setVersion("4.7")
        XCTAssertFalse(self.utility.hasUserEverDislikedApp())
        self.utility.declinedToRateCurrentVersion()

        self.utility.setVersion("4.8")
        XCTAssertFalse(self.utility.hasUserEverDislikedApp())
        self.utility.dislikedCurrentVersion()
        XCTAssertTrue(self.utility.hasUserEverDislikedApp())

        self.utility.setVersion("4.9")
        self.utility.likedCurrentVersion()
        XCTAssertTrue(self.utility.hasUserEverDislikedApp())
    }

    func testShouldPromptForAppReviewForSection() {
        self.utility.register(section: "notifications", significantEventCount: 2)
        self.utility.setVersion("4.7")
        XCTAssertFalse(self.utility.shouldPromptForAppReview(section: "notifications"))
        self.utility.incrementSignificantEvent(section: "notifications")
        XCTAssertFalse(self.utility.shouldPromptForAppReview(section: "notifications"))
        self.utility.incrementSignificantEvent(section: "notifications")
        XCTAssertTrue(self.utility.shouldPromptForAppReview(section: "notifications"))
    }

    func testShouldPromptAppReviewSystemWideWithEnoughSmallerSignficantEvents() {
        self.utility.register(section: "notifications", significantEventCount: 2)
        self.utility.register(section: "editor", significantEventCount: 2)
        self.utility.systemWideSignificantEventCountRequiredForPrompt = 3
        self.utility.setVersion("4.7")

        XCTAssertFalse(self.utility.shouldPromptForAppReview(section: "notifications"))
        XCTAssertFalse(self.utility.shouldPromptForAppReview(section: "editor"))
        XCTAssertFalse(self.utility.shouldPromptForAppReview())

        self.utility.incrementSignificantEvent(section: "notifications")
        self.utility.incrementSignificantEvent(section: "editor")
        XCTAssertFalse(self.utility.shouldPromptForAppReview())

        self.utility.incrementSignificantEvent(section: "editor")
        XCTAssertTrue(self.utility.shouldPromptForAppReview())
    }

    func testShouldPromptForAppReviewSystemWideWithEnoughSmallerSignificantEventsIncludingNonSectionedEvents() {
        self.utility.register(section: "notifications", significantEventCount: 2)
        self.utility.register(section: "editor", significantEventCount: 2)
        self.utility.systemWideSignificantEventCountRequiredForPrompt = 3
        self.utility.setVersion("4.7")

        XCTAssertFalse(self.utility.shouldPromptForAppReview(section: "notifications"))
        XCTAssertFalse(self.utility.shouldPromptForAppReview(section: "editor"))
        XCTAssertFalse(self.utility.shouldPromptForAppReview())

        self.utility.incrementSignificantEvent(section: "notifications")
        self.utility.incrementSignificantEvent(section: "editor")
        XCTAssertFalse(self.utility.shouldPromptForAppReview())

        self.utility.incrementSignificantEvent()
        XCTAssertTrue(self.utility.shouldPromptForAppReview())
    }

    func testAppReviewPromptRemoteDisableWhenRemoteCheckIndicatesEverythingIsEnabled() {
        self.utility.register(section: "notifications", significantEventCount: 1)
        self.utility.setVersion("4.7")
        self.utility.incrementSignificantEvent(section: "notifications")
        XCTAssertTrue(self.utility.shouldPromptForAppReview(section: "notifications"))

        self.stubAppReviewCheckWithFile("app-review-prompt-all-enabled.json")
        let expect = self.expectation(description: "remote check")
        self.utility.checkIfAppReviewPromptsHaveBeenDisabled(success: {() -> Void in
            expect.fulfill()
        }, failure: {() -> Void in
            XCTAssert(false, "This callback shouldn't get called")
            expect.fulfill()
        })
        self.waitForExpectations(timeout: 2.0, handler: nil)

        // We shouldn't disable the check when the remote check indicates everything is enabled
        XCTAssertTrue(self.utility.shouldPromptForAppReview(section: "notifications"))
    }

    func testAppReviewPromptRemoteDisableWhenRemoteCheckIndicatesNotificationsAreDisabled() {
        self.utility.register(section: "notifications", significantEventCount: 1)
        self.utility.setVersion("4.7")
        self.utility.incrementSignificantEvent(section: "notifications")
        XCTAssertTrue(self.utility.shouldPromptForAppReview(section: "notifications"))

        self.stubAppReviewCheckWithFile("app-review-prompt-notifications-disabled.json")
        let expect = self.expectation(description: "remote check")
        self.utility.checkIfAppReviewPromptsHaveBeenDisabled(success: {() -> Void in
            expect.fulfill()
        }, failure: {() -> Void in
            XCTAssert(false, "This callback shouldn't get called")
            expect.fulfill()
        })
        self.waitForExpectations(timeout: 2.0, handler: nil)

        // We should disable the check when the remote check indicates notifications is disabled
        XCTAssertFalse(self.utility.shouldPromptForAppReview(section: "notifications"))
    }

    func testAppReviewPromptRemoteDisableWhenRemoteCheckIndicatesEverythingIsDisabled() {
        self.utility.register(section: "notifications", significantEventCount: 1)
        self.utility.setVersion("4.7")
        self.utility.incrementSignificantEvent(section: "notifications")
        XCTAssertTrue(self.utility.shouldPromptForAppReview(section: "notifications"))

        self.stubAppReviewCheckWithFile("app-review-prompt-global-disable.json")
        let expect = self.expectation(description: "remote check")
        self.utility.checkIfAppReviewPromptsHaveBeenDisabled(success: {() -> Void in
            expect.fulfill()
        }, failure: {() -> Void in
            XCTAssert(false, "This callback shouldn't get called")
            expect.fulfill()
        })
        self.waitForExpectations(timeout: 2.0, handler: nil)

        // We should disable the check when the remote check indicates notifications is disabled
        XCTAssertFalse(self.utility.shouldPromptForAppReview(section: "notifications"))
    }

    func testAppReviewPromptRemoteDisableForGlobalPromptWhenRemoteCheckIndicatesEverythingIsDisabled() {
        self.utility.register(section: "notifications", significantEventCount: 1)
        self.utility.systemWideSignificantEventCountRequiredForPrompt = 2
        self.utility.setVersion("4.7")
        self.utility.incrementSignificantEvent(section: "notifications")
        self.utility.incrementSignificantEvent()
        XCTAssertTrue(self.utility.shouldPromptForAppReview())

        self.stubAppReviewCheckWithFile("app-review-prompt-global-disable.json")
        let expect = self.expectation(description: "remote check")
        self.utility.checkIfAppReviewPromptsHaveBeenDisabled(success: {() -> Void in
            expect.fulfill()
        }, failure: {() -> Void in
            XCTAssert(false, "This callback shouldn't get called")
            expect.fulfill()
        })
        self.waitForExpectations(timeout: 5.0, handler: nil)

        // We should disable the check when the remote check indicates notifications is disabled
        XCTAssertFalse(self.utility.shouldPromptForAppReview(section: "notifications"))
    }

    func testAppReviewNotPromptedSystemWideWhenDisabledLocally() {
        self.utility._overridePromptingDisabledLocal(true)
        self.utility.systemWideSignificantEventCountRequiredForPrompt = 1
        self.utility.incrementSignificantEvent()
        XCTAssertFalse(self.utility.shouldPromptForAppReview())
    }

    func testAppReviewNotPromptedForSectionWhenDisabledLocally() {
        self.utility._overridePromptingDisabledLocal(true)
        self.utility.register(section: "notifications", significantEventCount: 1)
        self.utility.incrementSignificantEvent(section: "notifications")
        XCTAssertFalse(self.utility.shouldPromptForAppReview(section: "notifications"))
    }

    func testAppReviewPromptedAfterEnoughTime() {
        let magicValue = -(Int(ceil(365 / 2)) + 1)
        let fourMonthsAgo = Calendar.current.date(byAdding: .day, value: magicValue, to: Date())
        self.utility._overrideLastPromptToRateDate(fourMonthsAgo!)
        self.utility.systemWideSignificantEventCountRequiredForPrompt = 1
        self.utility.incrementSignificantEvent()
        XCTAssertTrue(self.utility.shouldPromptForAppReview())
    }

    func testAppReviewNotPromptedBeforeEnoughTime() {
        let twoMonthsAgo = Calendar.current.date(byAdding: .day, value: -61, to: Date())
        self.utility._overrideLastPromptToRateDate(twoMonthsAgo!)
        self.utility.systemWideSignificantEventCountRequiredForPrompt = 1
        self.utility.incrementSignificantEvent()
        XCTAssertFalse(self.utility.shouldPromptForAppReview())
    }

    fileprivate func createConditionsForPositiveAppReviewPrompt() {
        self.utility.systemWideSignificantEventCountRequiredForPrompt = 1
        self.utility.incrementSignificantEvent()
    }

    fileprivate func stubAppReviewCheckWithFile(_ filename: String) {
        stub(condition: { request in
            return (request.url!.absoluteString as NSString).contains("app-review-prompt-check")
        }) { _ in
            let stubPath = OHPathForFile(filename, type(of: self))
            return fixture(filePath: stubPath!,
                           headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }
    }
}
