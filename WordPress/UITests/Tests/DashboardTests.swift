import UITestsFoundation
import XCTest

// These tests are Jetpack only.
class DashboardTests: XCTestCase {

    @MainActor
    override func setUp() async throws {
        setUpTestSuite()
        try await WireMock.resetScenario(scenario: "new_page_flow")

        try LoginFlow
            .loginWithoutSelectingSite(email: WPUITestCredentials.testWPcomUserEmail)
    }

    override func tearDownWithError() throws {
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

// Taken from a UI test in the Tumblr app
class SafariTests: XCTestCase {

    func testSafariLoadsURL() {
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        safari.launch()

        // [!] This test expect Safari to be in a clean state.
        //     This is usually the case in CI where we use a fresh Simulator, but might not be on a dev machine.
        //     Given this is only an experiment, I skipped handling "dirty" dev machine states.

        let addressBar = safari.textFields["Address"]
        XCTAssertTrue(addressBar.waitForExistence(timeout: 5))
        addressBar.tap()
        addressBar.typeText("http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")
        addressBar.typeText("\n")

        // We should now have a player, but it could be that the controls are not on screen.
        // If so, tap to reveal them.
        //
        // There is not assertion for the other branch of the if, but that okay as the check passing is implicit validation of the expected behavior.
        let playButton = safari.buttons["Play/Pause"]
        if playButton.waitForExistence(timeout: 5) == false {
            safari.tap()
            XCTAssertTrue(playButton.waitForExistence(timeout: 5))
        }
        safari.terminate()
    }
}
