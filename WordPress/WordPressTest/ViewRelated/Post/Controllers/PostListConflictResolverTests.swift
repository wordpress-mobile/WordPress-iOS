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

        var localDateString = ""
        var webDateString = ""
        if let localDate = post.dateModified {
            localDateString = PostListHelper.dateAndTime(for: localDate)
        }
        if let webDate = post.original?.dateModified {
            webDateString = PostListHelper.dateAndTime(for: webDate)
        }
        let expectedMessage = """
        This post has two versions that are in conflict. Select the version you would like to discard.

        Local:
        Saved on \(localDateString)

        Web:
        Saved on \(webDateString)
        """
        let expectedButtonTitle1 = "Discard Local"
        let expectedButtonTitle2 = "Discard Web"

        let conflictResolutionAlert = PostListConflictResolver.presentAlertController(for: post) { _ in }

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

    func testDiscardingLocalVersion() {
        let post = createConflictedPost()
        PostListConflictResolver.handle(post: post, in: postListViewController)
    }

    private func createConflictedPost() -> Post {
        let date = Date.init(timeIntervalSince1970: 0)
        let original = PostBuilder(context).published().with(remoteStatus: .sync).with(dateModified: date).build()
        let local = original.createRevision() as! Post
        local.dateModified = Calendar.current.date(byAdding: .day, value: 10, to: date)
        local.tags = "test"
        return local
    }

    private final class MockPostCoordinator: PostCoordinator {
        private(set) var cancelAutoUploadOfInvocations: Int = 0

        override func cancelAutoUploadOf(_ post: AbstractPost) {
            cancelAutoUploadOfInvocations += 1
        }

        override func save(_ postToSave: AbstractPost, automatedRetry: Bool = false, forceDraftIfCreating: Bool = false, defaultFailureNotice: Notice? = nil, completion: ((Result<AbstractPost, Error>) -> ())? = nil) {

        }
    }
}
