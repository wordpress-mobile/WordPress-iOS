import XCTest

/// Covers the Reader's actions on a post, and that each one reaches the server.
///
/// Runs on the fixtures backend, where the "server" is the fixtures: the app's requests are
/// logged with the fixture that answered each, so a test can check both that the action was sent
/// and that the app showed what came back. An action changes what the app has stored, so each
/// test starts from a reset app.
final class ReaderActionTests: JetpackUITestCase {
    override class var backend: Backend { .fixtures }

    private enum Fixture {
        static let post = "Optimizing Meat 2.0"
        /// The endpoint that likes that post, which is post 125073 on site 70135762.
        static let likeEndpoint = "/rest/v1.1/sites/70135762/posts/125073/likes/new"
        static let likeFixture = "wpcom/reader/reader_like_post.json"
    }

    func testLikingAPost() throws {
        let reader = try MySiteScreen(app: app)
            .goToReader()

        // Nothing is liked to begin with.
        let likes = try reader.goTo(.likes)
        try likes.wait(until: "an empty Likes stream") { likes.isEmpty }

        let recent = try likes.goBackToMenu().goTo(.recent)
        try recent.waitFor(recent.likeButton(ofPostTitled: Fixture.post))
        XCTAssertEqual(recent.likeButton(ofPostTitled: Fixture.post).label, "Like. 34 likes.")

        try recent.like(postTitled: Fixture.post)

        // The server was asked to like the post, once, and said it had.
        let request = try waitForRequest("POST", path: Fixture.likeEndpoint)
        XCTAssertEqual(request.status, 200)
        XCTAssertEqual(request.fixture, Fixture.likeFixture)
        XCTAssertEqual(try requestCount("POST", path: Fixture.likeEndpoint), 1)

        // The post is now in the Likes stream, which the app fetches again from the server.
        let likesAfter = try recent.goBackToMenu().goTo(.likes)
        try likesAfter.waitFor(likesAfter.post(titled: Fixture.post))
    }
}
