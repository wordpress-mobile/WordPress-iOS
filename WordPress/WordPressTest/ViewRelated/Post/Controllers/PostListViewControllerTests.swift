import UIKit
import XCTest
import Nimble

@testable import WordPress

class PostListViewControllerTests: XCTestCase {

    func testShowsGhostableTableView() {
        let context = TestContextManager().newDerivedContext()
        let blog = BlogBuilder(context).build()
        let postListViewController = PostListViewController.controllerWithBlog(blog)
        let _ = postListViewController.view

        postListViewController.startGhost()

        expect(postListViewController.placeholderTableView.isHidden).to(beFalse())
    }

    func testHidesGhostableTableView() {
        let context = TestContextManager().newDerivedContext()
        let blog = BlogBuilder(context).build()
        let postListViewController = PostListViewController.controllerWithBlog(blog)
        let _ = postListViewController.view

        postListViewController.stopGhost()

        expect(postListViewController.placeholderTableView.isHidden).to(beTrue())
    }

    func showTenMockedItemsInGhostableTableView() {
        let context = TestContextManager().newDerivedContext()
        let blog = BlogBuilder(context).build()
        let postListViewController = PostListViewController.controllerWithBlog(blog)
        let _ = postListViewController.view

        postListViewController.startGhost()

        expect(postListViewController.placeholderTableView.numberOfRows(inSection: 0)).to(equal(10))
    }

}
