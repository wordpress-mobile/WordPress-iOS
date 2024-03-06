import UITestsFoundation
import XCTest

// These tests are Jetpack only.
class DashboardTests: XCTestCase {

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
        try super.tearDownWithError()
    }

    @MainActor
    func testFreeToPaidCardNavigation() throws {
        setUpTestSuite(selectWPComSite: WPUITestCredentials.testWPcomFreeSite)
        try MySiteScreen()
            .scrollToFreeToPaidPlansCard()
            .verifyFreeToPaidPlansCard()
            .tapFreeToPaidPlansCard()
            .assertScreenIsLoaded()
            .searchDomain()
            .selectDomain()
            .goToPlanSelection()
            .assertScreenIsLoaded()
    }

    @MainActor
    func testPagesCardHeaderNavigation() throws {
        setUpTestSuite(selectWPComSite: WPUITestCredentials.testWPcomPaidSite)
        try MySiteScreen()
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

    @MainActor
    func testActivityLogCardHeaderNavigation() throws {
        setUpTestSuite(selectWPComSite: WPUITestCredentials.testWPcomPaidSite)
        try MySiteScreen()
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
