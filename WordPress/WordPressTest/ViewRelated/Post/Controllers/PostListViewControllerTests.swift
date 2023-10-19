import UIKit
import XCTest
import Nimble

@testable import WordPress

class PostListViewControllerTests: CoreDataTestCase {

    func testItCanHandleNewPostUpdatesEvenIfTheGhostViewIsStillVisible() throws {
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
        try mainContext.save()

        let postListViewController = PostListViewController.controllerWithBlog(blog)
        let _ = postListViewController.view

        let draftsIndex = postListViewController.filterTabBar.items.firstIndex(where: { $0.title == i18n("Drafts") }) ?? 1
        postListViewController.updateFilter(index: draftsIndex)

        postListViewController.startGhost()

        // When: Simulate a post being created
        // Then: This should not cause a crash
        //
        // Note that `XCTAssertNoThrow` catches `NSException`s as well as Swift's `throw`.
        //
        // This test originally used Nimble's `raiseException` but that matcher is no longer available in the SPM build.
        // See https://github.com/Quick/Nimble/blob/e313d9a67ec2e4171d416c61282e49fc3aadc7a4/Sources/Nimble/Matchers/RaisesException.swift#L1
        XCTAssertNoThrow(try {
            _ = PostBuilder(self.mainContext, blog: blog).with(status: .draft).build()
            try self.mainContext.save()
        }())
    }

}
