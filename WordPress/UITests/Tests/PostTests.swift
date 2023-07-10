import UITestsFoundation
import XCTest

class PostTests: XCTestCase {
    override func setUpWithError() throws {
        setUpTestSuite()
        try LoginFlow.login(
            siteUrl: WPUITestCredentials.testWPcomSiteAddress,
            email: WPUITestCredentials.testWPcomUserEmail,
            password: WPUITestCredentials.testWPcomPassword,
            title: WPUITestCredentials.testWPcomSiteForScheduledPost
        )

        try TabNavComponent()
            .goToBlockEditorScreen()
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
    }

    let title = "Scheduled Post"

    func testCreateScheduledPost() throws {
        try BlockEditorScreen()
            .enterTextInTitle(text: title)
            .openPostSettings()
            .updatePublishDate()
            .closePublishDateSelector()
            .closePostSettings()
            .schedulePost()
            .viewPublishedPost(withTitle: title)
            .verifyEpilogueDisplays(postTitle: title, siteAddress: WPUITestCredentials.testWPcomSiteForScheduledPost)
            .done()
    }
}
