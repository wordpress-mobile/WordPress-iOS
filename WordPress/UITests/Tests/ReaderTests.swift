import UITestsFoundation
import XCTest

class ReaderTests: XCTestCase {
    @MainActor
    override func setUp() async throws {
        setUpTestSuite(selectWPComSite: WPUITestCredentials.testWPcomPaidSite)
        try await WireMock.setUpScenario(scenario: "reader_subscriptions_flow")
        try await WireMock.setUpScenario(scenario: "reader_like_post_flow")

        try makeMainNavigationComponent()
            .goToReaderScreen()
    }

    func openStream(_ stream: ReaderMenuScreen.ReaderStream) throws -> ReaderScreen {
        if XCTestCase.isPad {
            return try ReaderScreen()
                .switchToStream(stream)
        } else {
            // iPhone starts on the root screen before you make any selection
            return try ReaderMenuScreen()
                .open(stream)
        }
    }
}

class ReaderTests_01: ReaderTests {
    func _testViewPost() throws {
        try openStream(.recent)
            .openLastPost()
            .verifyPostContentEquals(.expectedPostContent)
    }

    func _testViewPostInSafari() throws {
        try openStream(.recent)
            .openLastPostInSafari()
            .verifyPostContentEquals(.expectedPostContent)
    }

    func _testDiscover() throws {
        try openStream(.discover)
            .selectTag()
            .verifyTagLoaded()
            .followTag()
            .verifyTagFollowed()
    }
}

class ReaderTests_02: ReaderTests {
    func _testAddCommentToPost() throws {
        try openStream(.recent)
            .openLastPostComments()
            .verifyCommentsListEmpty()
            .replyToPost(.commentContent)
            .verifyCommentSent(.commentContent)
    }

    func _testSavePost() throws {
        // Get saved post label
        let (updatedReaderScreen, savedPostLabel) = try openStream(.saved)
            .verifySavedPosts(state: .withoutPosts)
            .switchToStream(.recent)
            .saveFirstPost()

        // Open saved posts tab and validate that the correct saved post is displayed
        try updatedReaderScreen
            .switchToStream(.saved)
            .verifySavedPosts(state: .withPosts, postLabel: savedPostLabel)
    }

    func _testLikePost() throws {
        try openStream(.likes)
            .verifyLikedPosts(state: .withoutPosts)
            .switchToStream(.recent)
            .likeFirstPost()
            .verifyFirstPostLiked()
            .switchToStream(.likes)
            .verifyLikedPosts(state: .withPosts)
    }
}

private extension String {
    static let commentContent = "🤖👍 #Testing 123 це тестовий коментар"
    static let expectedPostContent = "Aenean vehicula nunc in sapien rutrum, nec vehicula enim iaculis. Aenean vehicula nunc in sapien rutrum, nec vehicula enim iaculis. Proin dictum non ligula aliquam varius. Nam ornare accumsan ante, sollicitudin bibendum erat bibendum nec. Aenean vehicula nunc in sapien rutrum, nec vehicula enim iaculis."
    static let withoutPosts = "without posts"
    static let withPosts = "with posts"
}
