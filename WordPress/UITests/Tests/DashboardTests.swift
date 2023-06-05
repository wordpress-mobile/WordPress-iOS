import UITestsFoundation
import XCTest

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

    // This test is JP only.
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

    func testActivityLogCardHeaderNavigation() throws {
        try MySiteScreen()
            .scrollToActivityLogCard()
            .verifyActivityLogCard()
            .verifyActivityLogCard(hasActivityPartial: "Enabled Jetpack Social")
            .verifyActivityLogCard(hasActivityPartial: "The Jetpack connection")
            .verifyActivityLogCard(hasActivityPartial: "This site is connected to")
            .tapActivityLogCardHeader()
            .verifyActivityLogScreenLoaded()
            .verifyActivityLogScreen(hasActivityPartial: "Enabled Jetpack Social")
            .verifyActivityLogScreen(hasActivityPartial: "The Jetpack connection")
            .verifyActivityLogScreen(hasActivityPartial: "This site is connected to")
    }
}
