import UIKit
import XCTest
import Nimble

@testable import WordPress

/// Test cases for PostService.markAsFailedAndDraftIfNeeded()
class PostServiceMarkAsFailedAndDraftIfNeededTests: XCTestCase {
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
