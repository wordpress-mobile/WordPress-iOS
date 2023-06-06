import UITestsFoundation
import XCTest

// These tests are Jetpack only.
class DashboardTests: XCTestCase {

    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()
        setUpTestSuite()

        try LoginFlow
            .loginWithoutSelectingSite(email: WPUITestCredentials.testWPcomUserEmail)
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
        try super.tearDownWithError()
    }

    func testFreeToPaidCardNavigation() throws {
        try LoginEpilogueScreen()
            .continueWithSelectedSite(WPUITestCredentials.testWPcomFreeSite)
            .scrollToFreeToPaidPlansCard()
            .verifyFreeToPaidPlansCard()
            .tapFreeToPaidPlansCard()
            .assertScreenIsLoaded()
            .selectDomain()
            .goToPlanSelection()
            .verifyPlanSelectionScreenLoaded()
            .selectPlan()
            .purchase()
            .verifyDomainResultScreenLoaded()
            .dismissResultScreen()
    }

    func testPagesCardHeaderNavigation() throws {
        try LoginEpilogueScreen()
            .continueWithSelectedSite(WPUITestCredentials.testWPcomPaidSite)
            .scrollToPagesCard()
            .verifyPagesCard()
            .verifyPagesCard(hasPage: "Blog")
            .verifyPagesCard(hasPage: "Shop")
            .verifyPagesCard(hasPage: "Cart")
            .tapPagesCardHeader()
            .assertScreenIsLoaded()
            .verifyPagesScreen(hasPage: "Blog")
            .verifyPagesScreen(hasPage: "Shop")
            .verifyPagesScreen(hasPage: "Cart")
    }

    func testActivityLogCardHeaderNavigation() throws {
        try LoginEpilogueScreen()
            .continueWithSelectedSite(WPUITestCredentials.testWPcomPaidSite)
            .scrollToActivityLogCard()
            .verifyActivityLogCard()
            .verifyActivityLogCard(hasActivityPartial: "Enabled Jetpack Social")
            .verifyActivityLogCard(hasActivityPartial: "The Jetpack connection")
            .verifyActivityLogCard(hasActivityPartial: "This site is connected to")
            .tapActivityLogCardHeader()
            .assertScreenIsLoaded()
            .verifyActivityLogScreen(hasActivityPartial: "Enabled Jetpack Social")
            .verifyActivityLogScreen(hasActivityPartial: "The Jetpack connection")
            .verifyActivityLogScreen(hasActivityPartial: "This site is connected to")
    }
}
