import UIKit
import XCTest
import Nimble

@testable import WordPress

class PageListViewControllerTests: XCTestCase {

    private var contextManager: TestContextManager!
    private var context: NSManagedObjectContext! {
        contextManager.mainContext
    }

    override func setUp() {
        contextManager = TestContextManager()
        super.setUp()
    }

    override func tearDown() {
        contextManager.tearDown()
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
