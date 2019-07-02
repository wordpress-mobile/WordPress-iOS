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

    fileprivate var contextManager: TestContextManager!
    fileprivate var context: NSManagedObjectContext!

    override func setUp() {
        TestAnalytics.clean()
        contextManager = TestContextManager()
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = contextManager.mainContext
        Environment.replaceEnvironment(analytics: TestAnalytics.self)
    }

    func testStartGutenbergSessionWithoutContentAndTitle() {
        let post = AbstractPost(context: context)
        var session = PostEditorAnalyticsSession(editor: .gutenberg, post: post)
        session.start(hasUnsupportedBlocks: false)

        XCTAssertEqual(TestAnalytics.tracked.count, 1)

        let tracked = TestAnalytics.tracked.first

        XCTAssertEqual(tracked?.stat, WPAnalyticsStat.editorSessionStart)
        XCTAssertEqual(tracked?.value(for: "content_type"), PostEditorAnalyticsSession.ContentType.new.rawValue)
        XCTAssertEqual(tracked?.value(for: "editor"), PostEditorAnalyticsSession.Editor.gutenberg.rawValue)
    }

    func testStartGutenbergSessionWithTitleButNoContent() {
        let post = AbstractPost(context: context)
        post.postTitle = "Some Title"
        var session = PostEditorAnalyticsSession(editor: .gutenberg, post: post)
        session.start(hasUnsupportedBlocks: false)

        XCTAssertEqual(TestAnalytics.tracked.count, 1)

        let tracked = TestAnalytics.tracked.first

        XCTAssertEqual(tracked?.stat, WPAnalyticsStat.editorSessionStart)
        XCTAssertEqual(tracked?.value(for: "content_type"), PostEditorAnalyticsSession.ContentType.new.rawValue)
        XCTAssertEqual(tracked?.value(for: "editor"), PostEditorAnalyticsSession.Editor.gutenberg.rawValue)
    }

    func testStartGutenbergSessionWithTitleAndContent() {
        let post = AbstractPost(context: context)
        post.postTitle = "Some Title"
        post.content = PostContent.gutenberg

        var session = PostEditorAnalyticsSession(editor: .gutenberg, post: post)
        session.start(hasUnsupportedBlocks: false)

        XCTAssertEqual(TestAnalytics.tracked.count, 1)

        let tracked = TestAnalytics.tracked.first

        XCTAssertEqual(tracked?.stat, WPAnalyticsStat.editorSessionStart)
        XCTAssertEqual(tracked?.value(for: "content_type"), PostEditorAnalyticsSession.ContentType.gutenberg.rawValue)
        XCTAssertEqual(tracked?.value(for: "editor"), PostEditorAnalyticsSession.Editor.gutenberg.rawValue)
    }
}
