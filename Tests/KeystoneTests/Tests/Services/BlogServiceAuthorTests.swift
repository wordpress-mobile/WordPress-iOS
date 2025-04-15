import CoreData
import XCTest
@testable import WordPress

class BlogServiceAuthorTests: CoreDataTestCase {
    var blogService: BlogService!

    override func setUp() {
        super.setUp()

        blogService = BlogService(coreDataStack: contextManager)
    }

    override func tearDown() {
        super.tearDown()

        blogService = nil
    }

    func testUpdatingBlogAuthors() {
        let blog = Blog.createBlankBlog(in: mainContext)

        let notFoundAuthor = blog.getAuthorWith(id: 1)
        XCTAssertNil(notFoundAuthor)

        let remoteUser = RemoteUser()
        remoteUser.userID = 1

        blogService.updateBlogAuthors(for: blog, with: [remoteUser], in: mainContext)

        let author = blog.getAuthorWith(id: 1)
        XCTAssertNotNil(author)
    }

    /// Authors should be marked as not deleted from the blog on initial insertion, or reinsertion after being deleted.
    func testMarkingAuthorAsNotDeleted() throws {
        let blog = Blog.createBlankBlog(in: mainContext)

        let remoteUser = RemoteUser()
        remoteUser.userID = 1

        blogService.updateBlogAuthors(for: blog, with: [remoteUser], in: mainContext)

        let author = try XCTUnwrap(blog.getAuthorWith(id: 1))
        XCTAssertFalse(author.deletedFromBlog)

        // the author was removed, set as deleted
        blogService.updateBlogAuthors(for: blog, with: [], in: mainContext)

        let removedAuthor = try XCTUnwrap(blog.getAuthorWith(id: 1))
        XCTAssertTrue(removedAuthor.deletedFromBlog)

        // the author was added back, set as not deleted
        blogService.updateBlogAuthors(for: blog, with: [remoteUser], in: mainContext)

        let addedBackAuthor = try XCTUnwrap(blog.getAuthorWith(id: 1))
        XCTAssertFalse(addedBackAuthor.deletedFromBlog)
    }

    /// Authors that are no longer included in the remote user array from the API are marked as deleted.
    func testMarkingAuthorAsDeleted() throws {
        let blog = Blog.createBlankBlog(in: mainContext)

        let remoteUser1 = RemoteUser()
        remoteUser1.userID = 1

        let remoteUser2 = RemoteUser()
        remoteUser2.userID = 2

        blogService.updateBlogAuthors(for: blog, with: [remoteUser1, remoteUser2], in: mainContext)

        XCTAssertNotNil(blog.getAuthorWith(id: 1))
        XCTAssertNotNil(blog.getAuthorWith(id: 2))

        /// User 2 was deleted so the API only returned User 1
        blogService.updateBlogAuthors(for: blog, with: [remoteUser1], in: mainContext)

        XCTAssertNotNil(blog.getAuthorWith(id: 1))

        let author2 = try XCTUnwrap(blog.getAuthorWith(id: 2))
        XCTAssertTrue(author2.deletedFromBlog)
    }

    func testQueryingBlogAuthorById() throws {
        let blog = Blog.createBlankBlog(in: mainContext)

        let remoteUser = RemoteUser()
        remoteUser.userID = 1
        remoteUser.displayName = "Test Author"

        blogService.updateBlogAuthors(for: blog, with: [remoteUser], in: mainContext)

        let foundAuthor = try XCTUnwrap(blog.getAuthorWith(id: 1))
        XCTAssertEqual(foundAuthor.userID, 1)
        XCTAssertEqual(foundAuthor.displayName, "Test Author")

        let notFoundAuthor = blog.getAuthorWith(id: 2)
        XCTAssertNil(notFoundAuthor)
    }
}
