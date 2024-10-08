import UITestsFoundation
import XCTest

class PageTests: XCTestCase {

    @MainActor
    override func setUp() async throws {
        try await WireMock.setUpScenario(scenario: "new_page_flow")
        setUpTestSuite(selectWPComSite: WPUITestCredentials.testWPcomFreeSite)
    }

    override func tearDown() async throws {
        try await WireMock.resetScenario(scenario: "new_page_flow")
    }

    let postTitle = "New Blank Page"

    func testCreateBlankPage() throws {
        try MySiteScreen()
            .goToCreateSheet()
            .goToSitePage()
            .createBlankPage()
            .enterTextInTitle(text: postTitle, postType: .page)
            .publish()
            .confirm()

        // TODO: reimplement this part of the test (flaky)
//        try MySiteScreen()
//            .scrollToPagesCard()
//            .verifyPagePublished(title: postTitle)
    }
}
