import UIKit
import XCTest
import Nimble

@testable import WordPress

class PostServiceMarkAsFailedAndDraftTests: XCTestCase {
    func testMarkAPostAsFailedAndDraftIt() {
        let post = PostBuilder().build()
        let postService = PostService()

        postService.markAsFailedAndDraft(post: post)

        expect(post.remoteStatus).to(equal(.failed))
        expect(post.status).to(equal(.draft))
    }
}
