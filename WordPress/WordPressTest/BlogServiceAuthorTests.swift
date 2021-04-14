import CoreData
import XCTest
@testable import WordPress

class BlogServiceAuthorTests: XCTestCase {
    var contextManager: TestContextManager!
    var blogService: BlogService!
    var context: NSManagedObjectContext {
        return contextManager.mainContext
    }

    override func setUp() {
        super.setUp()

        contextManager = TestContextManager()
        blogService = BlogService(managedObjectContext: contextManager.mainContext)
    }

    override func tearDown() {
        super.tearDown()

        ContextManager.overrideSharedInstance(nil)
        contextManager.mainContext.reset()
        contextManager = nil
        blogService = nil
    }

    func testUpdatingBlogAuthors() {
        let blog = blogService.createBlog()

        let notFoundAuthor = blog.getAuthorWith(id: 1)
        XCTAssertNil(notFoundAuthor)

        let remoteUser = RemoteUser()
        remoteUser.userID = 1

        blogService.updateBlogAuthors(for: blog, with: [remoteUser])

        let author = blog.getAuthorWith(id: 1)
        XCTAssertNotNil(author)
    }

    func testRemovingBlogAuthor() {
        let blog = blogService.createBlog()

        let remoteUser1 = RemoteUser()
        remoteUser1.userID = 1

        let remoteUser2 = RemoteUser()
        remoteUser2.userID = 2

        blogService.updateBlogAuthors(for: blog, with: [remoteUser1, remoteUser2])

        XCTAssertNotNil(blog.getAuthorWith(id: 1))
        XCTAssertNotNil(blog.getAuthorWith(id: 2))

        /// User 2 was deleted so the API only returned User 1
        blogService.updateBlogAuthors(for: blog, with: [remoteUser1])

        XCTAssertNotNil(blog.getAuthorWith(id: 1))
        XCTAssertNil(blog.getAuthorWith(id: 2))
    }

    func testQueryingBlogAuthorById() throws {
        let blog = blogService.createBlog()

        let remoteUser = RemoteUser()
        remoteUser.userID = 1
        remoteUser.displayName = "Test Author"

        blogService.updateBlogAuthors(for: blog, with: [remoteUser])

        let foundAuthor = try XCTUnwrap(blog.getAuthorWith(id: 1))
        XCTAssertEqual(foundAuthor.userID, 1)
        XCTAssertEqual(foundAuthor.displayName, "Test Author")

        let notFoundAuthor = blog.getAuthorWith(id: 2)
        XCTAssertNil(notFoundAuthor)
    }
}
