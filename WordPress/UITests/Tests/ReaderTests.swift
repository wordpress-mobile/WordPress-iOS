import UITestsFoundation
import XCTest

class ReaderTests: XCTestCase {
    override func setUpWithError() throws {
        setUpTestSuite()

        try LoginFlow.login(
            siteUrl: WPUITestCredentials.testWPcomPaidSite,
            email: WPUITestCredentials.testWPcomUserEmail,
            password: WPUITestCredentials.testWPcomPassword
        )
        try TabNavComponent()
            .goToReaderScreen()
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
    }

    let expectedPostContent = "Aenean vehicula nunc in sapien rutrum, nec vehicula enim iaculis. Aenean vehicula nunc in sapien rutrum, nec vehicula enim iaculis. Proin dictum non ligula aliquam varius. Nam ornare accumsan ante, sollicitudin bibendum erat bibendum nec. Aenean vehicula nunc in sapien rutrum, nec vehicula enim iaculis."

    let commentContent = "Test comment."

    func testViewPost() throws {
        try ReaderScreen()
            .openLastPost()
            .verifyPostContentEquals(expectedPostContent)
    }

    func testViewPostInSafari() throws {
        try ReaderScreen()
            .openLastPostInSafari()
            .verifyPostContentEquals(expectedPostContent)
    }

    func testAddCommentToPost() throws {
        try ReaderScreen()
            .openLastPostComments()
            .verifyCommentsListEmpty()
            .replyToPost(commentContent)
            .verifyCommentSent(commentContent)
    }
}
