import UIKit
import XCTest
import Nimble

@testable import WordPress

class PostListViewControllerTests: XCTestCase {

    private var context: NSManagedObjectContext!

    override func setUp() {
        context = TestContextManager().mainContext
        super.setUp()
    }

    override func tearDown() {
        context = nil
        TestContextManager.overrideSharedInstance(nil)
        super.tearDown()
    }

    func testShowsGhostableTableView() {
        let blog = BlogBuilder(context).build()
        let postListViewController = PostListViewController.controllerWithBlog(blog)
        let _ = postListViewController.view

        postListViewController.startGhost()

        expect(postListViewController.placeholderTableView.isHidden).to(beFalse())
    }

    func testHidesGhostableTableView() {
        let blog = BlogBuilder(context).build()
        let postListViewController = PostListViewController.controllerWithBlog(blog)
        let _ = postListViewController.view

        postListViewController.stopGhost()

        expect(postListViewController.placeholderTableView.isHidden).to(beTrue())
    }

    func showTenMockedItemsInGhostableTableView() {
        let blog = BlogBuilder(context).build()
        let postListViewController = PostListViewController.controllerWithBlog(blog)
        let _ = postListViewController.view

        postListViewController.startGhost()

        expect(postListViewController.placeholderTableView.numberOfRows(inSection: 0)).to(equal(10))
    }
}
