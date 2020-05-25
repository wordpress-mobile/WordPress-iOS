import XCTest
import Nimble

@testable import WordPress

class ReaderDetailCoordinatorTests: XCTestCase {

    /// Given a post and site ID, fetches the post from the service
    ///
    func testRetrieveAReaderPostWhenSiteAndPostAreGiven() {
        let serviceMock = ReaderPostServiceMock()
        let viewMock = ReaderDetailViewMock()
        let coordinator = ReaderDetailCoordinator(service: serviceMock, view: viewMock)

        coordinator.fetch(postID: 1, siteID: 2, isFeed: false)

        expect(serviceMock.didCallFetchPostWithPostID).to(equal(1))
        expect(serviceMock.didCallFetchPostWithSiteID).to(equal(2))
        expect(serviceMock.didCallFetchPostWithIsFeed).to(beFalse())
    }

    /// Given the returned ReaderPost to the view
    ///
    func testUpdateViewWithRetrievedPost() {
        let post: ReaderPost = ReaderPostBuilder().build()
        let serviceMock = ReaderPostServiceMock()
        serviceMock.returnPost = post
        let viewMock = ReaderDetailViewMock()
        let coordinator = ReaderDetailCoordinator(service: serviceMock, view: viewMock)

        coordinator.fetch(postID: 1, siteID: 2, isFeed: false)

        expect(viewMock.didCallRenderWithPost).to(equal(post))
    }

    /// Given the returned ReaderPost to the view
    ///
    func testShowErrorInView() {
        let serviceMock = ReaderPostServiceMock()
        serviceMock.forceError = true
        let viewMock = ReaderDetailViewMock()
        let coordinator = ReaderDetailCoordinator(service: serviceMock, view: viewMock)

        coordinator.fetch(postID: 1, siteID: 2, isFeed: false)

        expect(viewMock.didCallShowError).to(beTrue())
    }

}

private class ReaderPostServiceMock: ReaderPostService {
    var didCallFetchPostWithPostID: UInt?
    var didCallFetchPostWithSiteID: UInt?
    var didCallFetchPostWithIsFeed: Bool?

    /// The post that should be returned by the mock
    var returnPost: ReaderPost?

    /// If we want to force an error
    var forceError = false

    override func fetchPost(_ postID: UInt, forSite siteID: UInt, isFeed: Bool, success: ((ReaderPost?) -> Void)!, failure: ((Error?) -> Void)!) {
        didCallFetchPostWithPostID = postID
        didCallFetchPostWithSiteID = siteID
        didCallFetchPostWithIsFeed = isFeed

        guard !forceError else {
            failure(nil)
            return
        }

        guard let returnPost = returnPost else {
            return
        }

        success(returnPost)
    }
}

private class ReaderDetailViewMock: ReaderDetailView {
    var didCallRenderWithPost: ReaderPost?
    var didCallShowError = false

    func render(_ post: ReaderPost) {
        didCallRenderWithPost = post
    }

    func showError() {
        didCallShowError = true
    }
}
