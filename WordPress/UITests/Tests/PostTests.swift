import UITestsFoundation
import XCTest

class PostTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        setUpTestSuite()

        try LoginFlow.login(
            siteUrl: WPUITestCredentials.testWPcomSiteAddress,
            email: WPUITestCredentials.testWPcomUserEmail,
            password: WPUITestCredentials.testWPcomPassword,
            selectedSiteTitle: WPUITestCredentials.testWPcomSiteForScheduledPost
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
            .schedulePost()
            .viewPublishedPost(withTitle: postTitle)
            .verifyEpilogueDisplays(postTitle: postTitle, siteAddress: WPUITestCredentials.testWPcomSiteForScheduledPost)
            .tapDone()
    }
}
