import UITestsFoundation
import XCTest

class PostTests: XCTestCase {

    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()
        setUpTestSuite(selectWPComSite: WPUITestCredentials.testWPcomSiteForScheduledPost)
    }

    let postTitle = "Scheduled Post"

    func testCreateScheduledPost() throws {
        try MySiteScreen()
            .goToBlockEditorScreen()
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
