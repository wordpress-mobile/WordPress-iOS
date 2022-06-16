import UIKit
import XCTest
import Nimble

@testable import WordPress

class PageListViewControllerTests: CoreDataTestCase {
    func testDoesNotShowGhostableTableView() {
        let blog = BlogBuilder(mainContext).build()
        let pageListViewController = PageListViewController.controllerWithBlog(blog)
        let _ = pageListViewController.view

        pageListViewController.startGhost()

        expect(pageListViewController.ghostableTableView.isHidden).to(beTrue())
    }
}
