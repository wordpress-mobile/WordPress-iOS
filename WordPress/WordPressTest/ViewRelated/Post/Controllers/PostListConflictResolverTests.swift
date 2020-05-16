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
        // title
        // message
        // button titles
        // button actions
    }

    func testDiscardLocalVersion() {

    }

    func testDiscardWebVersion() {
        
    }
}
