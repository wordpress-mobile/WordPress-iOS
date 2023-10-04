import UITestsFoundation
import XCTest

// These tests are Jetpack only.
class DashboardTests: XCTestCase {

    @MainActor
    override func setUp() async throws {
        setUpTestSuite()
        try await WireMock.setUpScenario(scenario: "new_page_flow")

        try LoginFlow
            .loginWithoutSelectingSite(email: WPUITestCredentials.testWPcomUserEmail)
    }

    override func tearDown() async throws {
        try await WireMock.resetScenario(scenario: "new_page_flow")
        takeScreenshotOfFailedTest()
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
            .assertScreenIsLoaded()
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
