import UITestsFoundation
import XCTest

class PageTests: XCTestCase {

    @MainActor
    override func setUp() async throws {
        setUpTestSuite()
        try await WireMock.setUpScenario(scenario: "new_page_flow")

        try LoginFlow.login(
            email: WPUITestCredentials.testWPcomUserEmail
        )
    }

    override func tearDown() async throws {
        try await WireMock.resetScenario(scenario: "new_page_flow")
        takeScreenshotOfFailedTest()
    }

    let postTitle = "New Blank Page"

    func testCreateBlankPage() throws {
        try TabNavComponent()
            .goToMySiteScreen()
            .goToCreateSheet()
            .goToSitePage()
            .enterTextInTitle(text: postTitle, postType: .page)
            .post(action: .publish, postType: .page)

        try MySiteScreen()
            .scrollToPagesCard()
            .verifyPagePublished(title: postTitle)
    }
}
