import UIKit
import XCTest
import Nimble

@testable import WordPress

class PostListViewControllerTests: CoreDataTestCase {

    func testShowsGhostableTableView() {
        let blog = BlogBuilder(mainContext).build()
        let postListViewController = PostListViewController.controllerWithBlog(blog)
        let _ = postListViewController.view

        postListViewController.startGhost()

        expect(postListViewController.ghostableTableView.isHidden).to(beFalse())
    }

    func testHidesGhostableTableView() {
        let blog = BlogBuilder(mainContext).build()
        let postListViewController = PostListViewController.controllerWithBlog(blog)
        let _ = postListViewController.view

        postListViewController.stopGhost()

        expect(postListViewController.ghostableTableView.isHidden).to(beTrue())
    }

    func testShowTenMockedItemsInGhostableTableView() {
        let blog = BlogBuilder(mainContext).build()
        let postListViewController = PostListViewController.controllerWithBlog(blog)
        let _ = postListViewController.view

        postListViewController.startGhost()

        expect(postListViewController.ghostableTableView.numberOfRows(inSection: 0)).to(equal(50))
    }

    func testItCanHandleNewPostUpdatesEvenIfTheGhostViewIsStillVisible() {
        // This test simulates and proves that the app will no longer crash on these conditions:
        //
        // 1. The app is built using Xcode 11 and running on iOS 13.1
        // 2. The user has no cached data on the device
        // 3. The user navigates to the Post List → Drafts
        // 4. The user taps on the plus (+) button which adds a post in the Drafts list
        //
        // Please see https://git.io/JeK3y for more information about this crash.
        //
        // This test fails when executed on 00c88b9b

        // Given
        let blog = BlogBuilder(mainContext).build()
        try! mainContext.save()

        let postListViewController = PostListViewController.controllerWithBlog(blog)
        let _ = postListViewController.view

        let draftsIndex = postListViewController.filterTabBar.items.firstIndex(where: { $0.title == i18n("Drafts") }) ?? 1
        postListViewController.updateFilter(index: draftsIndex)

        postListViewController.startGhost()

        // When: Simulate a post being created
        // Then: This should not cause a crash
        expect {
            _ = PostBuilder(self.mainContext, blog: blog).with(status: .draft).build()
            try! self.mainContext.save()
        }.notTo(raiseException())
    }

}
