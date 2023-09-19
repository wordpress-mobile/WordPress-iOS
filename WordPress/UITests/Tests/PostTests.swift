import UITestsFoundation
import XCTest

class PostTests: XCTestCase {

    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()
        setUpTestSuite()

        try LoginFlow.login(
            email: WPUITestCredentials.testWPcomUserEmail,
            siteAddress: WPUITestCredentials.testWPcomSiteForScheduledPost
        )

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
            .openPostSettings()
            .updatePublishDateToFutureDate()
            .closePublishDateSelector()
            .closePostSettings()
            .post(action: .schedule)
            .waitForNoticeToDisappear()

        // On iPad, the menu items are already listed on screen, so we don't need to tap More Menu button
        if XCUIDevice.isPhone {
            try MySiteScreen()
                .goToMoreMenu()
        }

        try MySiteMoreMenuScreen()
            .goToPostsScreen()
            .showOnly(.scheduled)
            .verifyPostExists(withTitle: postTitle)
    }
}
