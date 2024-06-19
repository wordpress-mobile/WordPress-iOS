import UITestsFoundation
import XCTest

class PostTests: XCTestCase {

    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()
        setUpTestSuite(selectWPComSite: WPUITestCredentials.testWPcomSiteForScheduledPost)

        try TabNavComponent()
            .goToBlockEditorScreen()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        takeScreenshotOfFailedTest()
    }

    let postTitle = "Scheduled Post"

    func testCreateScheduledPost() throws {
        try BlockEditorScreen()
            .enterTextInTitle(text: postTitle)
            .publish()
            .updatePublishDateToFutureDate()
            .confirm()

        try MySiteScreen()
            .goToMoreMenu()
            .goToPostsScreen()
            .showOnly(.scheduled)
            .verifyPostExists(withTitle: postTitle)
    }
}
