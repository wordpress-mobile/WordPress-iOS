import UIKit
import XCTest
import Nimble

@testable import WordPress

/// Test cases for PostService.markAsFailed()
class PostServiceMarkAsFailedTests: XCTestCase {

    private var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        context = TestContextManager().mainContext
    }

    override func tearDown() {
        super.tearDown()
        context = nil
        ContextManager.overrideSharedInstance(nil)
    }

    func testMarkAPostAsFailedAndKeepItsStatus() {
        let post = PostBuilder(context)
            .with(status: .pending)
            .withRemote()
            .build()
        let postService = PostService()

        postService.markAsFailed(post: post)

        expect(post.remoteStatus).to(equal(.failed))
        expect(post.status).to(equal(.pending))
    }

    func testMarksALocalPageAsFailedAndKeepItsStatus() {
        let page = PageBuilder(context)
            .with(status: .publish)
            .with(remoteStatus: .pushing)
            .with(dateModified: Date(timeIntervalSince1970: 0))
            .build()
        let postService = PostService()

        postService.markAsFailed(post: page)

        expect(page.remoteStatus).to(equal(.failed))
        expect(page.status).to(equal(.publish))
    }

    func testMarkingExistingPagesAsFailedWillNotRevertTheStatusToDraft() {
        let page = PageBuilder(context)
            .with(status: .scheduled)
            .with(remoteStatus: .pushing)
            .withRemote()
            .build()
        let postService = PostService()

        postService.markAsFailed(post: page)

        expect(page.status).to(equal(.scheduled))
        expect(page.remoteStatus).to(equal(.failed))
    }
}
