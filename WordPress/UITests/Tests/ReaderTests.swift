import UITestsFoundation
import XCTest

class ReaderTests: XCTestCase {

    @MainActor
    override func setUpWithError() throws {
        setUpTestSuite()

        try LoginFlow
            .login(email: WPUITestCredentials.testWPcomUserEmail)
        try TabNavComponent()
            .goToReaderScreen()
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
    }

    func testViewPost() throws {
        try ReaderScreen()
            .openLastPost()
            .verifyPostContentEquals(.expectedPostContent)
    }

    func testViewPostInSafari() throws {
        try ReaderScreen()
            .openLastPostInSafari()
            .verifyPostContentEquals(.expectedPostContent)
    }

    func testAddCommentToPost() throws {
        try ReaderScreen()
            .openLastPostComments()
            .verifyCommentsListEmpty()
            .replyToPost(.commentContent)
            .verifyCommentSent(.commentContent)
    }

    func testFollowNewTopicOnDiscover() throws {
        try ReaderScreen()
            .openDiscover()
            .selectTopic()
            .verifyTopicLoaded()
            .followTopic()
            .verifyTopicFollowed()
    }

    func testSavePost() throws {
        let (updatedReaderScreen, savedPostLabel) = try ReaderScreen()
            .openSavedPosts()
            .verifySavedPosts(state: .withoutSavedPosts)
            .openFollowing()
            .saveFirstPost()

        updatedReaderScreen
            .openSavedPosts()
            .verifySavedPosts(state: .withSavedPosts, postLabel: savedPostLabel)
    }
}

private extension String {
    static let commentContent = "🤖👍 #Testing 123 це тестовий коментар"
    static let expectedPostContent = "Aenean vehicula nunc in sapien rutrum, nec vehicula enim iaculis. Aenean vehicula nunc in sapien rutrum, nec vehicula enim iaculis. Proin dictum non ligula aliquam varius. Nam ornare accumsan ante, sollicitudin bibendum erat bibendum nec. Aenean vehicula nunc in sapien rutrum, nec vehicula enim iaculis."
    static let withoutSavedPosts = "without posts"
    static let withSavedPosts = "with posts"
}
