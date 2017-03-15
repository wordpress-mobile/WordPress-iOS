import XCTest
@testable import WordPress

class AppRatingUtilityTestsForInternalBuilds: XCTestCase {
    fileprivate var defaults: UserDefaults!
    fileprivate var utility: AppRatingUtility!


    override func setUp() {
        Build._overrideCurrent = .internal
        let appDomain: String? = Bundle.main.bundleIdentifier
        UserDefaults.standard.removePersistentDomain(forName: appDomain!)
        self.defaults = UserDefaults()
        self.utility = AppRatingUtility(defaults: self.defaults)
        self.utility.setVersion("1.0")
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testAppReviewNotPromptedSystemWide() {
        self.utility.systemWideSignificantEventCountRequiredForPrompt = 1
        self.utility.incrementSignificantEvent()
        XCTAssertFalse(self.utility.shouldPromptForAppReview())
    }

    func testAppReviewNotPromptedForSection() {
        self.utility.register(section: "notifications", significantEventCount: 1)
        self.utility.incrementSignificantEvent(section: "notifications")
        XCTAssertFalse(self.utility.shouldPromptForAppReview(section: "notifications"))
    }
}
