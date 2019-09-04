import UIKit
import XCTest
import Nimble

@testable import WordPress

class PostCoordinatorTests: XCTestCase {

    private let context = TestContextManager().newDerivedContext()
    
    func testDoNotUploadAPostWithFailedMedia() {
        let post = PostBuilder(context).with(image: "test.jpeg", status: .failed).build()
        let postServiceMock = PostServiceMock()
        let postCoordinator = PostCoordinator(mainService: postServiceMock, backgroundService: postServiceMock)

        postCoordinator.save(post: post)

        expect(post.remoteStatus).toEventually(equal(.failed))
        expect(postServiceMock.didCallUploadPost).to(beFalse())
    }

    func testUploadAPostWithNoFailedMedia() {
        let post = PostBuilder(context).with(image: "test.jpeg").build()
        let postServiceMock = PostServiceMock()
        let postCoordinator = PostCoordinator(mainService: postServiceMock, backgroundService: postServiceMock)

        postCoordinator.save(post: post)

        expect(postServiceMock.didCallUploadPost).to(beTrue())
    }
}

class PostServiceMock: PostService {
    var didCallUploadPost = false

    override func uploadPost(_ post: AbstractPost, success: ((AbstractPost) -> Void)?, failure: @escaping (Error?) -> Void) {
        didCallUploadPost = true
    }
}
