@testable import WordPress
import CoreData
import XCTest


class MockReblogPresenter: ReaderReblogPresenter {
    var presentReblogExpectation: XCTestExpectation?

    override func presentReblog(blogService: BlogService, readerPost: ReaderPost, origin: UIViewController) {
        presentReblogExpectation?.fulfill()
    }
}

class MockBlogService: BlogService {
    var blogsForAllAccountsExpectation: XCTestExpectation?
    var lastUsedOrFirstBlogExpectation: XCTestExpectation?

    var blogCount = 1

    override func blogCountVisibleForWPComAccounts() -> Int {
        return blogCount
    }

    override func visibleBlogsForWPComAccounts() -> [Blog] {
        blogsForAllAccountsExpectation?.fulfill()
        return [Blog(context: self.managedObjectContext), Blog(context: self.managedObjectContext)]
    }
    override func lastUsedOrFirstBlog() -> Blog? {
        lastUsedOrFirstBlogExpectation?.fulfill()
        return Blog(context: self.managedObjectContext)
    }
}

class ReblogTestCase: CoreDataTestCase {
    var readerPost: ReaderPost?
    var blogService: MockBlogService?
    var postService: PostService?

    override func setUp() {
        readerPost = ReaderPost(context: self.mainContext)
        blogService = MockBlogService(managedObjectContext: self.mainContext)
        postService = PostService(managedObjectContext: self.mainContext)
    }

    override func tearDown() {
        readerPost = nil
        blogService = nil
        postService = nil
    }
}

class ReaderReblogActionTests: ReblogTestCase {

    func testExecuteAction() {
        // Given
        let presenter = MockReblogPresenter(postService: postService!)
        presenter.presentReblogExpectation = expectation(description: "presentBlog was called")
        let action = ReaderReblogAction(blogService: blogService!, presenter: presenter)
        let controller = UIViewController()
        // When
        action.execute(readerPost: readerPost!, origin: controller, reblogSource: .list)
        // Then
        waitForExpectations(timeout: 4) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }
}

class ReblogPresenterTests: ReblogTestCase {

    func testPresentEditorForOneSite() throws {
        // Given
        let draftPosts = NSFetchRequest<Post>(entityName: "Post")
        draftPosts.predicate = NSPredicate(format: "status = %@", Post.Status.draft.rawValue)
        try XCTAssertEqual(mainContext.count(for: draftPosts), 0)
        blogService!.blogsForAllAccountsExpectation = expectation(description: "blogsForAllAccounts was called")
        let presenter = ReaderReblogPresenter(postService: postService!)
        // When
        presenter.presentReblog(blogService: blogService!, readerPost: readerPost!, origin: UIViewController())
        // Then
        try XCTAssertEqual(mainContext.count(for: draftPosts), 1)
        waitForExpectations(timeout: 4) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }

    func testPresentEditorForMultipleSites() {
        // Given
        blogService!.lastUsedOrFirstBlogExpectation = expectation(description: "lastUsedOrFirstBlog was called")
        blogService!.blogCount = 2
        let presenter = ReaderReblogPresenter(postService: postService!)
        // When
        presenter.presentReblog(blogService: blogService!, readerPost: readerPost!, origin: UIViewController())
        // Then
        waitForExpectations(timeout: 4) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }
}

class ReblogFormatterTests: XCTestCase {

    func testWordPressQuote() {
        // Given
        let quote = "Quote"
        // When
        let wpQuote = ReaderReblogFormatter.gutenbergQuote(text: quote)
        // Then
        XCTAssertEqual("<!-- wp:quote -->\n<blockquote class=\"wp-block-quote\"><p>Quote</p></blockquote>\n<!-- /wp:quote -->", wpQuote)
    }

    func testHyperLink() {
        // Given
        let url = "https://wordpress.com"
        let text = "WordPress.com"
        // When
        let wpLink = ReaderReblogFormatter.hyperLink(url: url, text: text)
        // Then
        XCTAssertEqual("<a href=\"https://wordpress.com\">WordPress.com</a>", wpLink)
    }

    func testImage() {
        // Given
        let image = "image.jpg"
        // When
        let wpImage = ReaderReblogFormatter.gutenbergImage(image: image)
        // Then
        XCTAssertEqual("<!-- wp:image {\"className\":\"size-large\"} -->\n" +
                       "<figure class=\"wp-block-image size-large\">" +
                       "<img src=\"image.jpg\" alt=\"\"/>" +
                       "</figure>\n<!-- /wp:image -->",
                       wpImage)
    }
}
