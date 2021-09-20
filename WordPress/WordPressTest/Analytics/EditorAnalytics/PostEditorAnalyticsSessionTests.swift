import Foundation
@testable import WordPress

class PostEditorAnalyticsSessionTests: XCTestCase {
    enum PostContent {
        static let classic = """
        Text <strong>bold</strong> <em>italic</em>
        """

        static let gutenberg = """
        <!-- wp:image {"id":-181231834} -->
        <figure class="wp-block-image"><img src="file://tmp/EC856C66-7B79-4631-9503-2FB9FF0E6C66.jpg" alt="" class="wp-image--181231834"/></figure>
        <!-- /wp:image -->
        """
    }

    private var contextManager: TestContextManager!
    private var context: NSManagedObjectContext!


    override func setUp() {
        contextManager = TestContextManager()
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = contextManager.mainContext
        TestAnalyticsTracker.setup()
    }

    override func tearDown() {
        TestAnalyticsTracker.tearDown()
    }

    func testStartGutenbergSessionWithoutContentAndTitle() {
        startSession(editor: .gutenberg)

        XCTAssertEqual(TestAnalyticsTracker.tracked.count, 1)

        let tracked = TestAnalyticsTracker.tracked.first

        XCTAssertEqual(tracked?.stat, WPAnalyticsStat.editorSessionStart)
        XCTAssertEqual(tracked?.value(for: "content_type"), PostEditorAnalyticsSession.ContentType.new.rawValue)
        XCTAssertEqual(tracked?.value(for: "editor"), PostEditorAnalyticsSession.Editor.gutenberg.rawValue)
    }

    func testStartGutenbergSessionWithTitleButNoContent() {
        startSession(editor: .gutenberg, postTitle: "Title")

        XCTAssertEqual(TestAnalyticsTracker.tracked.count, 1)

        let tracked = TestAnalyticsTracker.tracked.first

        XCTAssertEqual(tracked?.stat, WPAnalyticsStat.editorSessionStart)
        XCTAssertEqual(tracked?.value(for: "content_type"), PostEditorAnalyticsSession.ContentType.new.rawValue)
        XCTAssertEqual(tracked?.value(for: "editor"), PostEditorAnalyticsSession.Editor.gutenberg.rawValue)
    }

    func testStartGutenbergSessionWithTitleAndContent() {
        startSession(editor: .gutenberg, postTitle: "Title", postContent: PostContent.gutenberg)

        XCTAssertEqual(TestAnalyticsTracker.tracked.count, 1)

        let tracked = TestAnalyticsTracker.tracked.first

        XCTAssertEqual(tracked?.stat, WPAnalyticsStat.editorSessionStart)
        XCTAssertEqual(tracked?.value(for: "content_type"), PostEditorAnalyticsSession.ContentType.gutenberg.rawValue)
        XCTAssertEqual(tracked?.value(for: "editor"), PostEditorAnalyticsSession.Editor.gutenberg.rawValue)
    }

    func testTrackUnsupportedBlocksOnStart() {
        let unsupportedBlocks = ["unsupported"]
        startSession(editor: .gutenberg, unsupportedBlocks: unsupportedBlocks)

        XCTAssertEqual(TestAnalyticsTracker.tracked.count, 1)

        let tracked = TestAnalyticsTracker.tracked.first

        XCTAssertEqual(tracked?.stat, WPAnalyticsStat.editorSessionStart)
        let serializedArray = String(data: try! JSONSerialization.data(withJSONObject: unsupportedBlocks, options: .fragmentsAllowed), encoding: .utf8)
        XCTAssertEqual(tracked?.value(for: "unsupported_blocks"), serializedArray)
        XCTAssertEqual(tracked?.value(for: "has_unsupported_blocks"), "1")
    }

    func testTrackUnsupportedBlocksOnStartWithEmptyList() {
        let unsupportedBlocks = [String]()
        startSession(editor: .gutenberg, unsupportedBlocks: unsupportedBlocks)

        XCTAssertEqual(TestAnalyticsTracker.tracked.count, 1)

        let tracked = TestAnalyticsTracker.tracked.first

        XCTAssertEqual(tracked?.stat, WPAnalyticsStat.editorSessionStart)
        let serializedArray = String(data: try! JSONSerialization.data(withJSONObject: unsupportedBlocks, options: .fragmentsAllowed), encoding: .utf8)
        XCTAssertEqual(tracked?.value(for: "unsupported_blocks"), serializedArray)
        XCTAssertEqual(tracked?.value(for: "has_unsupported_blocks"), "0")
    }

    func testTrackUnsupportedBlocksOnSwitch() {
        let unsupportedBlocks = ["unsupported"]
        var session = startSession(editor: .gutenberg, unsupportedBlocks: unsupportedBlocks)
        session.switch(editor: .gutenberg)

        XCTAssertEqual(TestAnalyticsTracker.tracked.count, 2)

        let tracked = TestAnalyticsTracker.tracked.last

        XCTAssertEqual(tracked?.stat, WPAnalyticsStat.editorSessionSwitchEditor)
        XCTAssertEqual(tracked?.value(for: "has_unsupported_blocks"), "1")
        let trackedUnsupportedBlocks: [String]? = tracked?.value(for: "unsupported_blocks")
        XCTAssertNil(trackedUnsupportedBlocks)
    }

    func testTrackUnsupportedBlocksOnEnd() {
        let unsupportedBlocks = ["unsupported"]
        let session = startSession(editor: .gutenberg, unsupportedBlocks: unsupportedBlocks)
        session.end(outcome: .publish)

        XCTAssertEqual(TestAnalyticsTracker.tracked.count, 2)

        let tracked = TestAnalyticsTracker.tracked.last

        XCTAssertEqual(tracked?.stat, WPAnalyticsStat.editorSessionEnd)
        XCTAssertEqual(tracked?.value(for: "has_unsupported_blocks"), "1")
        let trackedUnsupportedBlocks: [String]? = tracked?.value(for: "unsupported_blocks")
        XCTAssertNil(trackedUnsupportedBlocks)
    }

    func testTrackBlogIdOnStart() {
        startSession(editor: .gutenberg, blogID: 123)

        XCTAssertEqual(TestAnalyticsTracker.tracked.count, 1)

        let tracked = TestAnalyticsTracker.tracked.first

        XCTAssertEqual(tracked?.stat, WPAnalyticsStat.editorSessionStart)
        XCTAssertEqual(tracked?.value(for: "blog_id"), "123")
    }

    func testTrackBlogIdOnSwitch() {
        var session = startSession(editor: .gutenberg, blogID: 456)
        session.switch(editor: .gutenberg)

        XCTAssertEqual(TestAnalyticsTracker.tracked.count, 2)

        let tracked = TestAnalyticsTracker.tracked.last

        XCTAssertEqual(tracked?.stat, WPAnalyticsStat.editorSessionSwitchEditor)
        XCTAssertEqual(tracked?.value(for: "blog_id"), "456")
    }

    func testTrackBlogIdOnEnd() {
        let session = startSession(editor: .gutenberg, blogID: 789)
        session.end(outcome: .publish)

        XCTAssertEqual(TestAnalyticsTracker.tracked.count, 2)

        let tracked = TestAnalyticsTracker.tracked.last

        XCTAssertEqual(tracked?.stat, WPAnalyticsStat.editorSessionEnd)
        XCTAssertEqual(tracked?.value(for: "blog_id"), "789")
    }
}

extension PostEditorAnalyticsSessionTests {
    func createPost(title: String? = nil, body: String? = nil, blogID: NSNumber? = nil) -> AbstractPost {
        let post = AbstractPost(context: context)
        post.postTitle = title
        post.content = body
        post.blog = Blog(context: context)
        post.blog.dotComID = blogID
        return post
    }

    @discardableResult
    func startSession(editor: PostEditorAnalyticsSession.Editor, postTitle: String? = nil, postContent: String? = nil, unsupportedBlocks: [String] = [], blogID: NSNumber? = nil) -> PostEditorAnalyticsSession {
        let post = createPost(title: postTitle, body: postContent, blogID: blogID)
        var session = PostEditorAnalyticsSession(editor: .gutenberg, post: post)
        session.start(unsupportedBlocks: unsupportedBlocks)
        return session
    }
}
