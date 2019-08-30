import CoreData
import XCTest
@testable import WordPress

class BlogServiceDeduplicationTests: XCTestCase {
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

    func testDeduplicationDoesNothingWhenNoDuplicates() {
        let account = createAccount()
        let blog1 = createBlog(id: 1, url: "blog1.example.com", account: account)
        let blog2 = createBlog(id: 2, url: "blog2.example.com", account: account)
        createDraft(title: "Post 1 in Blog 2", blog: blog2, id: 1)
        createDraft(title: "Draft 2 in Blog 2", blog: blog2)
        let blog3 = createBlog(id: 3, url: "blog3.example.com", account: account)

        XCTAssertEqual(account.blogs.count, 3)
        XCTAssertEqual(blog1.posts?.count, 0)
        XCTAssertEqual(blog2.posts?.count, 2)
        XCTAssertEqual(blog3.posts?.count, 0)

        deduplicateAndSave(account)

        XCTAssertEqual(account.blogs.count, 3)
        XCTAssertEqual(blog1.posts?.count, 0)
        XCTAssertEqual(blog2.posts?.count, 2)
        XCTAssertEqual(blog3.posts?.count, 0)
    }

    func testDeduplicationRemovesDuplicateBlogsWithoutDrafts() {
        let account = createAccount()
        createBlog(id: 1, url: "blog1.example.com", account: account)
        createBlog(id: 2, url: "blog2.example.com", account: account)
        createBlog(id: 2, url: "blog2.example.com", account: account)

        XCTAssertEqual(account.blogs.count, 3)

        deduplicateAndSave(account)

        XCTAssertEqual(account.blogs.count, 2)
    }

    func testDeduplicationPrefersCandidateWithLocalDrafts() {
        let account = createAccount()

        let blog1 = createBlog(id: 1, url: "blog1.example.com", account: account)

        let blog2a = createBlog(id: 2, url: "blog2.example.com", account: account)
        createDraft(title: "Post 1 in Blog 2", blog: blog2a, id: 1)
        createDraft(title: "Draft 2 in Blog 2", blog: blog2a)
        let blog2b = createBlog(id: 2, url: "blog2.example.com", account: account)

        let blog3a = createBlog(id: 3, url: "blog3.example.com", account: account)
        let blog3b = createBlog(id: 3, url: "blog3.example.com", account: account)
        createDraft(title: "Post 1 in Blog 3", blog: blog3b, id: 1)
        createDraft(title: "Draft 2 in Blog 3", blog: blog3b)

        XCTAssertEqual(account.blogs.count, 5)
        XCTAssertEqual(blog1.posts?.count, 0)
        XCTAssertEqual(blog2a.posts?.count, 2)
        XCTAssertEqual(blog2b.posts?.count, 0)
        XCTAssertEqual(blog3a.posts?.count, 0)
        XCTAssertEqual(blog3b.posts?.count, 2)

        deduplicateAndSave(account)

        XCTAssertEqual(account.blogs.count, 3)
        XCTAssertEqual(account.blogs, Set(arrayLiteral: blog1, blog2a, blog3b))

        XCTAssertFalse(isDeleted(blog1))
        XCTAssertFalse(isDeleted(blog2a))
        XCTAssertTrue(isDeleted(blog2b))
        XCTAssertTrue(isDeleted(blog3a))
        XCTAssertFalse(isDeleted(blog3b))

        XCTAssertEqual(blog1.posts?.count, 0)
        XCTAssertEqual(blog2a.posts?.count, 2)
        XCTAssertEqual(blog3b.posts?.count, 2)
    }

    func testDeduplicationMigratesLocalDrafts() {
        let account = createAccount()

        let blog1 = createBlog(id: 1, url: "blog1.example.com", account: account)

        let blog2a = createBlog(id: 2, url: "blog2.example.com", account: account)
        createDraft(title: "Post 1 in Blog 2", blog: blog2a, id: 1)
        createDraft(title: "Draft 2 in Blog 2", blog: blog2a)
        let blog2b = createBlog(id: 2, url: "blog2.example.com", account: account)
        createDraft(title: "Post 1 in Blog 2", blog: blog2b, id: 1)
        createDraft(title: "Post 3 in Blog 2", blog: blog2b, id: 3)
        createDraft(title: "Draft 4 in Blog 2", blog: blog2b)

        XCTAssertEqual(account.blogs.count, 3)
        XCTAssertEqual(blog1.posts?.count, 0)
        XCTAssertEqual(blog2a.posts?.count, 2)
        XCTAssertEqual(blog2b.posts?.count, 3)

        deduplicateAndSave(account)

        XCTAssertEqual(account.blogs.count, 2)

        XCTAssertFalse(isDeleted(blog1))
        // We don't care which one is deleted, but one of them should be
        XCTAssertTrue(isDeleted(blog2a) != isDeleted(blog2b), "Exactly one copy of Blog 2 should have been deleted")

        XCTAssertEqual(blog1.posts?.count, 0)
        guard let blog2Final = account.blogs.first(where: { $0.dotComID == 2 }) else {
            return XCTFail("There should be one blog with ID = 2")
        }
        XCTAssertTrue(findPost(title: "Post 1 in Blog 2", in: blog2Final))
        XCTAssertTrue(findPost(title: "Draft 2 in Blog 2", in: blog2Final))
        XCTAssertTrue(findPost(title: "Draft 4 in Blog 2", in: blog2Final))
    }
}

private extension BlogServiceDeduplicationTests {
    func deduplicateAndSave(_ account: WPAccount) {
        blogService.deduplicateBlogs(for: account)
        contextManager.saveContextAndWait(context)
    }

    func isDeleted(_ object: NSManagedObject) -> Bool {
        return object.isDeleted || object.managedObjectContext == nil
    }

    func findPost(title: String, in blog: Blog) -> Bool {
        return blog.posts?.contains(where: { (post) in
            post.postTitle?.contains(title) ?? false
        }) ?? false
    }

    @discardableResult
    func createAccount() -> WPAccount {
        let accountService = AccountService(managedObjectContext: context)
        return accountService.createOrUpdateAccount(withUsername: "twoface", authToken: "twotoken")
    }

    @discardableResult
    func createBlog(id: Int, url: String, account: WPAccount) -> Blog {
        let blog = NSEntityDescription.insertNewObject(forEntityName: "Blog", into: context) as! Blog
        blog.dotComID = id as NSNumber
        blog.url = url
        blog.xmlrpc = url
        blog.account = account
        return blog
    }

    @discardableResult
    func createDraft(title: String, blog: Blog, id: Int? = nil) -> AbstractPost {
        let post = NSEntityDescription.insertNewObject(forEntityName: "Post", into: context) as! Post
        post.postTitle = title
        post.blog = blog
        post.postID = id.map({ $0 as NSNumber })
        return post
    }
}
