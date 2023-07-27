import UITestsFoundation
import XCTest

class NUXTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        setUpTestSuite()

        try PrologueScreen()
            .selectSiteAddress()
            .proceedWithWordPress(siteUrl: WPUITestCredentials.testWPcomSiteAddress)
            .proceedWith(email: WPUITestCredentials.testWPcomUserEmail)
            .proceedWithValidPassword()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        takeScreenshotOfFailedTest()
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
