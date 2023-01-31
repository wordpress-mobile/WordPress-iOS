@testable import WordPress
import CoreData
import XCTest


class MockReblogPresenter: ReaderReblogPresenter {
    var presentReblogExpectation: XCTestExpectation?

    override func presentReblog(coreDataStack: CoreDataStack, readerPost: ReaderPost, origin: UIViewController) {
        presentReblogExpectation?.fulfill()
    }
}

class ReblogTestCase: CoreDataTestCase {
    var readerPost: ReaderPost?
    var postService: PostService?

    override func setUp() {
        readerPost = ReaderPost(context: self.mainContext)
        postService = PostService(managedObjectContext: self.mainContext)
    }

    override func tearDown() {
        readerPost = nil
        postService = nil
    }
}

class ReaderReblogActionTests: ReblogTestCase {

    func testExecuteAction() {
        // Given
        let presenter = MockReblogPresenter(postService: postService!)
        presenter.presentReblogExpectation = expectation(description: "presentBlog was called")
        let action = ReaderReblogAction(coreDataStack: contextManager, presenter: presenter)
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
        BlogBuilder(contextManager.mainContext).with(visible: true).isHostedAtWPcom().withAnAccount().build()
        // TODO: Replace this expectation with other ways to assert the `ReaderReblogPresenter.presentEditor` is called.
        let draftPosts = NSFetchRequest<Post>(entityName: "Post")
        draftPosts.predicate = NSPredicate(format: "status = %@", Post.Status.draft.rawValue)
        try XCTAssertEqual(mainContext.count(for: draftPosts), 0)
        let presenter = ReaderReblogPresenter(postService: postService!)
        // When
        presenter.presentReblog(coreDataStack: contextManager, readerPost: readerPost!, origin: UIViewController())
        // Then
        try XCTAssertEqual(mainContext.count(for: draftPosts), 1)
    }

    func testPresentEditorForMultipleSites() {
        // Given
        for _ in 1...2 {
            BlogBuilder(contextManager.mainContext).with(visible: true).isHostedAtWPcom().withAnAccount().build()
        }
        let presenter = ReaderReblogPresenter(postService: postService!)
        let origin = MockViewController()
        origin.presentExpectation = expectation(description: "blog selector is presented")
        // When
        presenter.presentReblog(coreDataStack: contextManager, readerPost: readerPost!, origin: origin)
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

private class MockViewController: UIViewController {

    var presentExpectation: XCTestExpectation?

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        presentExpectation?.fulfill()
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }

}
