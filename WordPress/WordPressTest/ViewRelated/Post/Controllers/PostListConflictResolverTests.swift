import Foundation
import XCTest

@testable import WordPress

class PostListConflictResolverTests: XCTestCase {

    private var context: NSManagedObjectContext!
    var postListViewController: PostListViewController!
    var blog: Blog!

    override func setUp() {
        super.setUp()
        context = TestContextManager().mainContext
        blog = BlogBuilder(context).build()
        postListViewController = PostListViewController.controllerWithBlog(blog)
    }

    override func tearDown() {
        context = nil
        TestContextManager.overrideSharedInstance(nil)
        super.tearDown()
    }

    func testAlertPresentsCorrectOptions() {
        let post = createConflictedPost()
        let expectedTitle = "Resolve sync conflict"
        let expectedMessage = """
        This post has two versions that are in conflict. Select the version you would like to discard.

        Local:
        Saved on Jan 10, 1970 @ 7:00 PM

        Web:
        Saved on Dec 31, 1969 @ 7:00 PM
        """
        let expectedButtonTitle1 = "Discard Local"
        let expectedButtonTitle2 = "Discard Web"

        let conflictResolutionAlert = PostListConflictResolver.presentConflictResolutionAlert(for: post) { _ in }

        let expectation = XCTestExpectation(description: "Testing alert exists")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
            XCTAssertEqual(conflictResolutionAlert.title, expectedTitle)
            XCTAssertEqual(conflictResolutionAlert.message, expectedMessage)
            XCTAssertTrue(conflictResolutionAlert.actions.count == 2)
            XCTAssertEqual(conflictResolutionAlert.actions.first?.title, expectedButtonTitle1)
            XCTAssertEqual(conflictResolutionAlert.actions.last?.title, expectedButtonTitle2)
          expectation.fulfill()
        })
        wait(for: [expectation], timeout: 5)
    }

    private func createConflictedPost() -> Post {
        let date = Date.init(timeIntervalSince1970: 0)
        let original = PostBuilder(context).published().with(remoteStatus: .sync).with(dateModified: date).build()
        let local = original.createRevision() as! Post
        local.dateModified = Calendar.current.date(byAdding: .day, value: 10, to: date)
        local.tags = "test"
        return local
    }
}
