import UIKit
import XCTest
import Nimble

@testable import WordPress

class PageListViewControllerTests: XCTestCase {

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

    func testDoesNotShowGhostableTableView() {
        let blog = BlogBuilder(context).build()
        let pageListViewController = PageListViewController.controllerWithBlog(blog)
        let _ = pageListViewController.view

        pageListViewController.startGhost()

        expect(pageListViewController.ghostableTableView.isHidden).to(beTrue())
    }
}
