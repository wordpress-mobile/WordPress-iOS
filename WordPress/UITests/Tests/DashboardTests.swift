import UITestsFoundation
import XCTest

// These tests are Jetpack only.
class DashboardTests: XCTestCase {
    override func setUpWithError() throws {
        setUpTestSuite()

        try LoginFlow.login(
            siteUrl: WPUITestCredentials.testWPcomSiteAddress,
            email: WPUITestCredentials.testWPcomUserEmail,
            password: WPUITestCredentials.testWPcomPassword
        )
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
        removeApp()
    }


    func testFreeToPaidCardNavigation() throws {
        try MySiteScreen()
            .scrollToFreeToPaidPlansCard()
            .verifyFreeToPaidPlansCard()
            .tapFreeToPaidPlansCard()
            .verifyDomainsSuggestionsScreenLoaded()
            .selectDomain()
            .goToPlanSelection()
            .verifyPlanSelectionScreenLoaded()
    }

    func testPagesCardHeaderNavigation() throws {
        try MySiteScreen()
            .scrollToPagesCard()
            .verifyPagesCard()
            .verifyPagesCard(hasPage: "Blog")
            .verifyPagesCard(hasPage: "Shop")
            .verifyPagesCard(hasPage: "Cart")
            .tapPagesCardHeader()
            .verifyPagesScreenLoaded()
    }
}
