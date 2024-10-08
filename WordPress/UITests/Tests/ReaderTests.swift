import UITestsFoundation
import XCTest

class ReaderTests: XCTestCase {
    @MainActor
    override func setUp() async throws {
        setUpTestSuite(selectWPComSite: WPUITestCredentials.testWPcomPaidSite)
        try await WireMock.setUpScenario(scenario: "reader_subscriptions_flow")
        try await WireMock.setUpScenario(scenario: "reader_like_post_flow")

        _ = try makeMainNavigationComponent()
            .goToReaderScreen()
    }
}

class ReaderTests_01: ReaderTests {
    func testViewPost() throws {
        try ReaderScreen()
            .switchToStream(.subscriptions)
            .openLastPost()
            .verifyPostContentEquals(.expectedPostContent)
    }

    func testViewPostInSafari() throws {
        try ReaderScreen()
            .switchToStream(.subscriptions)
            .openLastPostInSafari()
            .verifyPostContentEquals(.expectedPostContent)
    }

    func testDiscover() throws {
        try ReaderScreen()
            .switchToStream(.discover)
            .selectTag()
            .verifyTagLoaded()
            .followTag()
            .verifyTagFollowed()
    }
}

class ReaderTests_02: ReaderTests {
    func testAddCommentToPost() throws {
        try ReaderScreen()
            .switchToStream(.subscriptions)
            .openLastPostComments()
            .verifyCommentsListEmpty()
            .replyToPost(.commentContent)
            .verifyCommentSent(.commentContent)
    }

    func testInteractWithPost() throws {
        try _testSavePost()
        try _testLikePost()
    }

    func _testSavePost() throws {
        // Get saved post label
        let (updatedReaderScreen, savedPostLabel) = try ReaderScreen()
            .switchToStream(.saved)
            .verifySavedPosts(state: .withoutPosts)
            .switchToStream(.subscriptions)
            .saveFirstPost()

        // Open saved posts tab and validate that the correct saved post is displayed
        updatedReaderScreen
            .switchToStream(.saved)
            .verifySavedPosts(state: .withPosts, postLabel: savedPostLabel)
    }

    func _testLikePost() throws {
        try ReaderScreen()
            .switchToStream(.liked)
            .verifyLikedPosts(state: .withoutPosts)
            .switchToStream(.subscriptions)
            .likeFirstPost()
            .verifyPostLikedOnFollowingTab()
            .switchToStream(.liked)
            .verifyLikedPosts(state: .withPosts)
    }
}

private extension String {
    static let commentContent = "🤖👍 #Testing 123 це тестовий коментар"
    static let expectedPostContent = "Aenean vehicula nunc in sapien rutrum, nec vehicula enim iaculis. Aenean vehicula nunc in sapien rutrum, nec vehicula enim iaculis. Proin dictum non ligula aliquam varius. Nam ornare accumsan ante, sollicitudin bibendum erat bibendum nec. Aenean vehicula nunc in sapien rutrum, nec vehicula enim iaculis."
    static let withoutPosts = "without posts"
    static let withPosts = "with posts"
}
