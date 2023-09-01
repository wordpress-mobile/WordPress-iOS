import UITestsFoundation
import XCTest

class PageTests: XCTestCase {

    @MainActor
    override func setUpWithError() throws {
        setUpTestSuite()

        try LoginFlow.login(
            email: WPUITestCredentials.testWPcomUserEmail
        )
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
    }

    let postTitle = "New Blank Page"

    func testCreateBlankPage() throws {
        try TabNavComponent()
            .goToMySiteScreen()
            .goToCreateSheet()
            .goToSitePage()
            .createBlankPage()
            .enterTextInTitle(text: postTitle, postType: .page)
            .post(action: .publish, postType: .page)

        try MySiteScreen()
            .scrollToPagesCard()
            .verifyPagePublished()
    }
}
