@testable import WordPress
import CoreData
import XCTest


class MockReblogPresenter: ReblogPresenter {
    var presentReblogExpectation: XCTestExpectation?

    override func presentReblog(blogs: [Blog], readerPost: ReaderPost, origin: UIViewController) {
        presentReblogExpectation?.fulfill()
    }
}

class MockBlogService: BlogService {
    var blogsExpectation: XCTestExpectation?
    override init(managedObjectContext context: NSManagedObjectContext) {
        super.init(managedObjectContext: context)
    }

    override func blogsForAllAccounts() -> [Blog] {
        blogsExpectation?.fulfill()
        return []
    }
}

class ReaderReblogActionTests: XCTestCase {
    var context: NSManagedObjectContext?

    override func setUp() {
        self.context = setUpInMemoryManagedObjectContext()
    }

    override func tearDown() {
        self.context = nil
    }

    func testExecuteAction() {
        // Given
        let readerPost = ReaderPost(context: self.context!)
        let presenter = MockReblogPresenter(postService: nil)
        let blogService = MockBlogService(managedObjectContext: self.context!)
        blogService.blogsExpectation = expectation(description: "blogsForAllAccounts was called")
        presenter.presentReblogExpectation = expectation(description: "presentBlog was called")
        let action = ReaderReblogAction(blogService: blogService, presenter: presenter)
        let controller = UIViewController()
        // When
        action.execute(readerPost: readerPost, origin: controller)

        // Then
        waitForExpectations(timeout: 4) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }
    /// creates an in-memory store
    func setUpInMemoryManagedObjectContext() -> NSManagedObjectContext? {

        do {
            let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle.main])
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel!)
            try persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
            let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
            return managedObjectContext
        } catch {
            print("Adding in-memory persistent store failed")
            return nil
        }
    }
}

class ReblogFormatterTests: XCTestCase {

    func testWordPressQuote() {
        // Given
        let quote = "Quote"
        // When
        let wpQuote = ReblogFormatter.wordPressQuote(text: quote)
        // Then
        XCTAssertEqual("<!-- wp:quote -->\n<blockquote class=\"wp-block-quote\"><p>Quote</p></blockquote>\n<!-- /wp:quote -->", wpQuote)
    }

    func testHyperLink() {
        // Given
        let url = "https://wordpress.com"
        let text = "WordPress.com"
        // When
        let wpLink = ReblogFormatter.hyperLink(url: url, text: text)
        // Then
        XCTAssertEqual("<a href=\"https://wordpress.com\">WordPress.com</a>", wpLink)
    }

    func testImage() {
        // Given
        let image = "image.jpg"
        // When
        let wpImage = ReblogFormatter.htmlImage(image: image)
        // Then
        XCTAssertEqual("<!-- wp:paragraph -->\n<p><img src=\"image.jpg\"></p>\n<!-- /wp:paragraph -->", wpImage)
    }
}
