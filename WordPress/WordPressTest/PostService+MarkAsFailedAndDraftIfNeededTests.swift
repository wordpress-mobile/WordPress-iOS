import UIKit
import XCTest
import Nimble

@testable import WordPress

/// Test cases for PostService.markAsFailedAndDraftIfNeeded()
class PostServiceMarkAsFailedAndDraftIfNeededTests: XCTestCase {
    func testMarkAPostAsFailedAndDraftIt() {
        let post = PostBuilder()
            .with(status: .pending)
            .build()
        let postService = PostService()

        postService.markAsFailedAndDraftIfNeeded(post: post)

        expect(post.remoteStatus).to(equal(.failed))
        expect(post.status).to(equal(.draft))
    }

    func testItWillMarkLocallyPublishedPostsAsFailedButKeepTheStatus() {
        let post = PostBuilder().published().with(remoteStatus: .local).build()
        let postService = PostService()

        postService.markAsFailedAndDraftIfNeeded(post: post)

        expect(post.remoteStatus).to(equal(.failed))
        expect(post.status).to(equal(.publish))
    }

    func testMarkAPostAsFailedAndKeepItsStatus() {
        let post = PostBuilder()
            .with(status: .pending)
            .withRemote()
            .build()
        let postService = PostService()

        postService.markAsFailedAndDraftIfNeeded(post: post)

        expect(post.remoteStatus).to(equal(.failed))
        expect(post.status).to(equal(.pending))
    }
}
