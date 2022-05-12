import XCTest
@testable import WordPress

class SharingServiceTests: XCTestCase {
    var contextManager: ContextManagerMock!
    var context: NSManagedObjectContext {
        return contextManager.mainContext
    }

    override func setUp() {
        super.setUp()

        contextManager = ContextManagerMock()
    }

    func testSyncingPublicizeConnectionsForNonDotComBlogCallsACompletionBlock() throws {
        let blogService = BlogService(managedObjectContext: context)
        let blog = blogService.createBlog()
        blog.account = nil

        let expect = expectation(description: "Sharing service completion block called.")

        let sharingService = SharingService(managedObjectContext: context)
        sharingService.syncPublicizeConnectionsForBlog(blog) {
            expect.fulfill()
        } failure: { (error) in
            expect.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }
}
