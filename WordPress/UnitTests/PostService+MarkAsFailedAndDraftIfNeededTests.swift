import UIKit
import XCTest
import Nimble

@testable import WordPress

/// Test cases for Post.markAsFailedAndDraftIfNeeded()
class PostMarkAsFailedAndDraftIfNeededTests: CoreDataTestCase {

    func testMarkAPostAsFailedAndKeepItsStatus() {
        let post = PostBuilder(mainContext)
            .with(status: .pending)
            .withRemote()
            .build()

        post.markAsFailedAndDraftIfNeeded()

        expect(post.remoteStatus).to(equal(.failed))
        expect(post.status).to(equal(.pending))
    }

    func testMarkAPostAsFailedKeepShouldAttemptAutoUpload() {
        let blog = BlogBuilder(mainContext).withAnAccount().build()
        let post = PostBuilder(mainContext, blog: blog)
            .with(status: .pending)
            .confirmedAutoUpload()
            .build()

        post.markAsFailedAndDraftIfNeeded()

        expect(post.shouldAttemptAutoUpload).to(beTrue())
    }

    func testMarksALocalPageAsFailedAndResetsItToDraft() {
        let page = PageBuilder(mainContext)
            .with(status: .publish)
            .with(remoteStatus: .pushing)
            .with(dateModified: Date(timeIntervalSince1970: 0))
            .build()

        page.markAsFailedAndDraftIfNeeded()

        expect(page.remoteStatus).to(equal(.failed))
        expect(page.status).to(equal(.draft))
        expect(page.dateModified).to(beCloseTo(Date(), within: 3))
    }

    func testMarkingExistingPagesAsFailedWillNotRevertTheStatusToDraft() {
        let page = PageBuilder(mainContext)
            .with(status: .scheduled)
            .with(remoteStatus: .pushing)
            .withRemote()
            .build()

        page.markAsFailedAndDraftIfNeeded()

        expect(page.status).to(equal(.scheduled))
        expect(page.remoteStatus).to(equal(.failed))
    }
}
