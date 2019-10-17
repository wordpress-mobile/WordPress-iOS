import UIKit
import XCTest
import Nimble

@testable import WordPress

/// Test cases for PostService.markAsFailedAndDraftIfNeeded()
class PostServiceMarkAsFailedAndDraftIfNeededTests: XCTestCase {

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

        postService.markAsFailedAndDraftIfNeeded(post: post)

        expect(post.remoteStatus).to(equal(.failed))
        expect(post.status).to(equal(.pending))
    }

    func testMarksALocalPageAsFailedAndResetsItToDraft() {
        let page = PageBuilder(context)
            .with(status: .publish)
            .with(remoteStatus: .pushing)
            .with(dateModified: Date(timeIntervalSince1970: 0))
            .build()
        let postService = PostService()

        postService.markAsFailedAndDraftIfNeeded(post: page)

        expect(page.remoteStatus).to(equal(.failed))
        expect(page.status).to(equal(.draft))
        expect(page.dateModified).to(beCloseTo(Date(), within: 3))
    }

    func testMarkingExistingPagesAsFailedWillNotRevertTheStatusToDraft() {
        let page = PageBuilder(context)
            .with(status: .scheduled)
            .with(remoteStatus: .pushing)
            .withRemote()
            .build()
        let postService = PostService()

        postService.markAsFailedAndDraftIfNeeded(post: page)

        expect(page.status).to(equal(.scheduled))
        expect(page.remoteStatus).to(equal(.failed))
    }
}
