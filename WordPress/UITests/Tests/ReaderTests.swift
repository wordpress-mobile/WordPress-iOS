import UITestsFoundation
import XCTest

class ReaderTests: XCTestCase {

    @MainActor
    override func setUp() async throws {
        setUpTestSuite()
        try await WireMock.setUpScenario(scenario: "reader_like_post_flow")

        try LoginFlow
            .login(email: WPUITestCredentials.testWPcomUserEmail)
        try TabNavComponent()
            .goToReaderScreen()
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
    }

//    func testViewPost() throws {
//        try ReaderScreen()
//            .openLastPost()
//            .verifyPostContentEquals(.expectedPostContent)
//    }

//    func testViewPostInSafari() throws {
//        try ReaderScreen()
//            .openLastPostInSafari()
//            .verifyPostContentEquals(.expectedPostContent)
//    }

//    func testAddCommentToPost() throws {
//        try ReaderScreen()
//            .openLastPostComments()
//            .verifyCommentsListEmpty()
//            .replyToPost(.commentContent)
//            .verifyCommentSent(.commentContent)
//    }

//    func testFollowNewTopicOnDiscover() throws {
//        try ReaderScreen()
//            .openDiscoverTab()
//            .selectTopic()
//            .verifyTopicLoaded()
//            .followTopic()
//            .verifyTopicFollowed()
//    }

//    func testSavePost() throws {
//        // Get saved post label
//        let (updatedReaderScreen, savedPostLabel) = try ReaderScreen()
//            .openSavedTab()
//            .verifySavedPosts(state: .withoutPosts)
//            .openFollowingTab()
//            .saveFirstPost()
//
//        // Open saved posts tab and validate that the correct saved post is displayed
//        updatedReaderScreen
//            .openSavedTab()
//            .verifySavedPosts(state: .withPosts, postLabel: savedPostLabel)
//    }

//    func testLikePost() throws {
//        try ReaderScreen()
//            .openLikesTab()
//            .verifyLikedPosts(state: .withoutPosts)
//            .openFollowingTab()
//            .likeFirstPost()
//            .verifyPostLikedOnFollowingTab()
//            .openLikesTab()
//            .verifyLikedPosts(state: .withPosts)
//    }
}

private extension String {
    static let commentContent = "🤖👍 #Testing 123 це тестовий коментар"
    static let expectedPostContent = "Aenean vehicula nunc in sapien rutrum, nec vehicula enim iaculis. Aenean vehicula nunc in sapien rutrum, nec vehicula enim iaculis. Proin dictum non ligula aliquam varius. Nam ornare accumsan ante, sollicitudin bibendum erat bibendum nec. Aenean vehicula nunc in sapien rutrum, nec vehicula enim iaculis."
    static let withoutPosts = "without posts"
    static let withPosts = "with posts"
}
