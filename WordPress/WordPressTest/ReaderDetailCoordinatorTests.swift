import XCTest
import Nimble

@testable import WordPress

class ReaderDetailCoordinatorTests: XCTestCase {

    /// Given a post ID, site ID and isFeed fetches the post from the service
    ///
    func testRetrieveAReaderPostWhenSiteAndPostAreGiven() {
        let serviceMock = ReaderPostServiceMock()
        let viewMock = ReaderDetailViewMock()
        let coordinator = ReaderDetailCoordinator(service: serviceMock, view: viewMock)
        coordinator.set(postID: 1, siteID: 2, isFeed: true)

        coordinator.start()

        expect(serviceMock.didCallFetchPostWithPostID).to(equal(1))
        expect(serviceMock.didCallFetchPostWithSiteID).to(equal(2))
        expect(serviceMock.didCallFetchPostWithIsFeed).to(beTrue())
    }

    /// Inform the view to render a post after it is fetched
    ///
    func testUpdateViewWithRetrievedPost() {
        let post: ReaderPost = ReaderPostBuilder().build()
        let serviceMock = ReaderPostServiceMock()
        serviceMock.returnPost = post
        let viewMock = ReaderDetailViewMock()
        let coordinator = ReaderDetailCoordinator(service: serviceMock, view: viewMock)
        coordinator.set(postID: 1, siteID: 2, isFeed: false)

        coordinator.start()

        expect(viewMock.didCallRenderWithPost).to(equal(post))
    }

    /// When an error happens, tell the view to show an error
    ///
    func testShowErrorInView() {
        let serviceMock = ReaderPostServiceMock()
        serviceMock.forceError = true
        let viewMock = ReaderDetailViewMock()
        let coordinator = ReaderDetailCoordinator(service: serviceMock, view: viewMock)
        coordinator.set(postID: 1, siteID: 2, isFeed: false)

        coordinator.start()

        expect(viewMock.didCallShowError).to(beTrue())
    }

    /// Inform the view to show post title after it is fetched
    ///
    func testShowTitleAfterPostIsFetched() {
        let post: ReaderPost = ReaderPostBuilder().build()
        post.postTitle = "Foobar"
        let serviceMock = ReaderPostServiceMock()
        serviceMock.returnPost = post
        let viewMock = ReaderDetailViewMock()
        let coordinator = ReaderDetailCoordinator(service: serviceMock, view: viewMock)
        coordinator.set(postID: 1, siteID: 2, isFeed: false)

        coordinator.start()

        expect(viewMock.didCallShowTitleWith).to(equal("Foobar"))
    }

    /// If a post is given, do not call the servce and render the content right away
    ///
    func testGivenAPostRenderItRightAway() {
        let post: ReaderPost = ReaderPostBuilder().build()
        let serviceMock = ReaderPostServiceMock()
        let viewMock = ReaderDetailViewMock()
        let coordinator = ReaderDetailCoordinator(service: serviceMock, view: viewMock)
        coordinator.post = post

        coordinator.start()

        expect(viewMock.didCallRenderWithPost).to(equal(post))
        expect(serviceMock.didCallFetchPostWithPostID).to(beNil())
    }

    /// If a post is given, show it's title right away
    ///
    func testGivenAPostShowItsTitle() {
        let post: ReaderPost = ReaderPostBuilder().build()
        post.postTitle = "Reader"
        let serviceMock = ReaderPostServiceMock()
        let viewMock = ReaderDetailViewMock()
        let coordinator = ReaderDetailCoordinator(service: serviceMock, view: viewMock)
        coordinator.post = post

        coordinator.start()

        expect(viewMock.didCallShowTitleWith).to(equal("Reader"))
        expect(serviceMock.didCallFetchPostWithPostID).to(beNil())
    }

    /// Show the share sheet
    ///
    func testShowShareSheet() {
        let button = UIView()
        let post: ReaderPost = ReaderPostBuilder().build()
        let serviceMock = ReaderPostServiceMock()
        let viewMock = ReaderDetailViewMock()
        let postSharingControllerMock = PostSharingControllerMock()
        let coordinator = ReaderDetailCoordinator(service: serviceMock, sharingController: postSharingControllerMock, view: viewMock)
        coordinator.post = post

        coordinator.share(fromView: button)

        expect(postSharingControllerMock.didCallShareReaderPostWith).to(equal(post))
        expect(postSharingControllerMock.didCallShareReaderPostWithView).to(equal(button))
        expect(postSharingControllerMock.didCallShareReaderPostWithViewController).to(equal(viewMock))
    }

    /// Present a site preview in the current view stack
    ///
    func testShowPresentSitePreview() {
        let post: ReaderPost = ReaderPostBuilder().build()
        post.siteID = 1
        post.isExternal = false
        let serviceMock = ReaderPostServiceMock()
        let viewMock = ReaderDetailViewMock()
        let postSharingControllerMock = PostSharingControllerMock()
        let coordinator = ReaderDetailCoordinator(service: serviceMock, sharingController: postSharingControllerMock, view: viewMock)
        let navigationControllerMock = UINavigationControllerMock()
        viewMock.navigationController = navigationControllerMock
        coordinator.post = post

        coordinator.didTapBlogName()

        expect(navigationControllerMock.didCallPushViewControllerWith).toEventually(beAKindOf(ReaderStreamViewController.self))
    }

    /// Present a tag in the current view stack
    ///
    func testShowPresentTag() {
        let post: ReaderPost = ReaderPostBuilder().build()
        post.primaryTagSlug = "tag"
        let serviceMock = ReaderPostServiceMock()
        let viewMock = ReaderDetailViewMock()
        let postSharingControllerMock = PostSharingControllerMock()
        let coordinator = ReaderDetailCoordinator(service: serviceMock, sharingController: postSharingControllerMock, view: viewMock)
        let navigationControllerMock = UINavigationControllerMock()
        viewMock.navigationController = navigationControllerMock
        coordinator.post = post

        coordinator.didTapTagButton()

        expect(navigationControllerMock.didCallPushViewControllerWith).toEventually(beAKindOf(ReaderStreamViewController.self))
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

private class ReaderDetailViewMock: UIViewController, ReaderDetailView {
    var didCallRenderWithPost: ReaderPost?
    var didCallShowError = false
    var didCallShowTitleWith: String?

    private var _navigationController: UINavigationController?
    override var navigationController: UINavigationController? {
        set {
            _navigationController = newValue
        }

        get {
            return _navigationController
        }
    }

    func render(_ post: ReaderPost) {
        didCallRenderWithPost = post
    }

    func showError() {
        didCallShowError = true
    }

    func show(title: String?) {
        didCallShowTitleWith = title
    }
}

private class PostSharingControllerMock: PostSharingController {
    var didCallShareReaderPostWith: ReaderPost?
    var didCallShareReaderPostWithView: UIView?
    var didCallShareReaderPostWithViewController: UIViewController?

    override func shareReaderPost(_ post: ReaderPost, fromView anchorView: UIView, inViewController viewController: UIViewController) {
        didCallShareReaderPostWith = post
        didCallShareReaderPostWithView = anchorView
        didCallShareReaderPostWithViewController = viewController
    }
}

private class UINavigationControllerMock: UINavigationController {
    var didCallPushViewControllerWith: UIViewController?

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        didCallPushViewControllerWith = viewController
    }
}
