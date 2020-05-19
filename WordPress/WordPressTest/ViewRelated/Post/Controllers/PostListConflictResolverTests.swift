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

    func testDiscardWebVersion() {
        let post = createConflictedPost()
        PostListConflictResolver.handle(post: post, in: postListViewController)
        PostListConflictResolver.discardWebVersion(post: post, in: postListViewController)

        let actual = PostListConflictResolver.post?.postTitle
        let expected = PostListConflictResolver.localClone?.postTitle

        XCTAssertEqual(actual, expected)
    }

    func testDiscardLocalVersion() {
        let post = createConflictedPost()
        PostListConflictResolver.handle(post: post, in: postListViewController)
        PostListConflictResolver.discardLocalVersion(post: post, in: postListViewController)

        let actual = PostListConflictResolver.post?.postTitle
        let expected = PostListConflictResolver.webClone?.postTitle

        XCTAssertEqual(actual, expected)
    }

    // MARK: - Private methods

    private func createConflictedPost() -> Post {
        let date = Date.init(timeIntervalSince1970: 0)
        let webPost = PostBuilder(context).published().with(remoteStatus: .sync).with(dateModified: date).build()
        webPost.postTitle = "Post saved on web"
        let localPost = webPost.createRevision()
        localPost.dateModified = Calendar.current.date(byAdding: .day, value: 10, to: date)
        localPost.postTitle = "Post updated, but not saved, locally"
        return localPost as! Post
    }
}
