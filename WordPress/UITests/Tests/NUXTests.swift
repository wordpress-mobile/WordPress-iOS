import UITestsFoundation
import XCTest

class NUXTests: XCTestCase {

    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()
        setUpTestSuite()

        try LoginFlow.loginWithoutSelectingSite(email: WPUITestCredentials.testWPcomUserEmail)
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
        try super.tearDownWithError()
    }

    let siteTitle = "New Testing Site"
    let domainName = "domainexample.blog"

    func testCreateNewSiteWithQuickStart() throws {
        try LoginEpilogueScreen()
            .tapCreateNewSite()
            .skipSiteTopicAndTheme()
            .chooseDomainName(domainName)
            .verifySiteCreated()
            .tapDoneButton()
            .proceedToCustomizeYourSite()

        // Breaking the chain because after tapping on customize your site, My Site screen is displayed briefly before the Quick Start screen is displayed
        // Test fails when validating elements on Quick Start screen because My Site's element tree is the one loaded first
        try QuickStartCustomizeScreen()
            .verifyCustomizeSiteListDisplayed()
            .tapCheckSiteTitle()
            .verifyCheckSiteTitleNoticeDisplayed(siteTitle)
    }
}
