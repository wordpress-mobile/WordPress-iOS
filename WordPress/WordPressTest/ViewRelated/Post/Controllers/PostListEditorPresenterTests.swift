import Foundation
import XCTest

@testable import WordPress

class PostListEditorPresenterTests: XCTestCase {

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

    func testVersionConflictAlertShouldNotPresentWithoutVersionConflict() {
        let post = PostBuilder(context).revision().with(remoteStatus: .sync).with(dateModified: Date()).build()
        // getting a false positive
        PostListEditorPresenter.handle(post: post, in: postListViewController)

        XCTAssertFalse(postListViewController.presentedViewController is UIAlertController)
    }

    func testVersionConflictAlertShouldPresentIfConflict() {
        let post = postWithVersionConflict(in: blog)

        PostListEditorPresenter.handle(post: post, in: postListViewController, hasVersionConflict: true)

        XCTAssertTrue(postListViewController.presentedViewController is UIAlertController)
        XCTAssertEqual(postListViewController.presentedViewController?.title, "Test Title")
    }

    func testAlertPresentsCorrectOptions() {
        // title
        // message
        // button titles
        // button actions
    }

    fileprivate func postWithVersionConflict(in blog: Blog) -> Post {
        let original = PostBuilder(context, blog: blog)
            .published()
            .with(remoteStatus: .sync)
            .with(dateModified: Date())
            .build()
        original.content = "something"
        original.tags = "nothing"
        
        let local = original.createRevision() as! Post
        local.dateModified = Date() - 5
        local.content = "testy mctesterson"
        local.tags = "test"
        return local
    }
}
