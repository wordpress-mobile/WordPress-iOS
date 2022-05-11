import XCTest
@testable import WordPress

class SharingServiceTests: CoreDataTestCase {
    func testSyncingPublicizeConnectionsForNonDotComBlogCallsACompletionBlock() throws {
        let blogService = BlogService(managedObjectContext: mainContext)
        let blog = blogService.createBlog()
        blog.account = nil

        let expect = expectation(description: "Sharing service completion block called.")

        let sharingService = SharingService(managedObjectContext: mainContext)
        sharingService.syncPublicizeConnectionsForBlog(blog) {
            expect.fulfill()
        } failure: { (error) in
            expect.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }
}
