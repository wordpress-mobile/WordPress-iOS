import XCTest
import Nimble

@testable import WordPress

class ReaderDetailCoordinatorTests: XCTestCase {

    /// Given a post ID, site ID and isFeed fetches the post from the service
    ///
    func testRetrieveAReaderPostWhenSiteAndPostAreGiven() {
        let serviceMock = ReaderPostServiceMock()
        let viewMock = ReaderDetailViewMock()
        let coordinator = ReaderDetailCoordinator(readerPostService: serviceMock, view: viewMock)
        coordinator.set(postID: 1, siteID: 2, isFeed: true)

        coordinator.start()

        expect(serviceMock.didCallFetchPostWithPostID).to(equal(1))
        expect(serviceMock.didCallFetchPostWithSiteID).to(equal(2))
        expect(serviceMock.didCallFetchPostWithIsFeed).to(beTrue())
    }

    /// Given a URL, retrieves the post
    ///
    func testRetrieveAReaderPostWhenURLIsGiven() {
        let serviceMock = ReaderPostServiceMock()
        let viewMock = ReaderDetailViewMock()
        let coordinator = ReaderDetailCoordinator(readerPostService: serviceMock, view: viewMock)
        coordinator.postURL = URL(string: "https://wpmobilep2.wordpress.com/post/")

        coordinator.start()

        expect(serviceMock.didCallFetchWithURL).to(equal(URL(string: "https://wpmobilep2.wordpress.com/post/")))
    }

    /// Inform the view to render a post after it is fetched
    ///
    func testUpdateViewWithRetrievedPost() {
        let post: ReaderPost = ReaderPostBuilder().build()
        let serviceMock = ReaderPostServiceMock()
        serviceMock.returnPost = post
        let viewMock = ReaderDetailViewMock()
        let coordinator = ReaderDetailCoordinator(readerPostService: serviceMock, view: viewMock)
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
        let coordinator = ReaderDetailCoordinator(readerPostService: serviceMock, view: viewMock)
        coordinator.set(postID: 1, siteID: 2, isFeed: false)

        coordinator.start()

        expect(viewMock.didCallShowError).to(beTrue())
    }

    /// When an error happens, tell the view to show an error
    ///
    func testShowErrorWithWebActionInView() {
        let serviceMock = ReaderPostServiceMock()
        serviceMock.forceError = true
        let viewMock = ReaderDetailViewMock()
        let coordinator = ReaderDetailCoordinator(readerPostService: serviceMock, view: viewMock)
        coordinator.postURL = URL(string: "https://wordpress.com/")

        coordinator.start()

        expect(viewMock.didCallShowErrorWithWebAction).to(beTrue())
    }

    /// When an error happens, call the callback
    ///
    func testCallCallbackWhenAnErrorHappens() {
        var didCallPostLoadFailureBlock = false
        let serviceMock = ReaderPostServiceMock()
        serviceMock.forceError = true
        let viewMock = ReaderDetailViewMock()
        let coordinator = ReaderDetailCoordinator(readerPostService: serviceMock, view: viewMock)
        coordinator.postURL = URL(string: "https://wordpress.com/")
        coordinator.postLoadFailureBlock = {
            didCallPostLoadFailureBlock = true
        }

        coordinator.start()

        expect(didCallPostLoadFailureBlock).to(beTrue())
        expect(coordinator.postLoadFailureBlock).to(beNil())
    }

    /// If a post is given, do not call the servce and render the content right away
    ///
    func testGivenAPostRenderItRightAway() {
        let post: ReaderPost = ReaderPostBuilder().build()
        let serviceMock = ReaderPostServiceMock()
        let viewMock = ReaderDetailViewMock()
        let coordinator = ReaderDetailCoordinator(readerPostService: serviceMock, view: viewMock)
        coordinator.post = post

        coordinator.start()

        expect(viewMock.didCallRenderWithPost).to(equal(post))
        expect(serviceMock.didCallFetchPostWithPostID).to(beNil())
    }

    /// Tell the view to show a loading indicator when start is called
    ///
    func testStartCallsTheViewToShowLoader() {
        let post: ReaderPost = ReaderPostBuilder().build()
        let serviceMock = ReaderPostServiceMock()
        let viewMock = ReaderDetailViewMock()
        let coordinator = ReaderDetailCoordinator(readerPostService: serviceMock, view: viewMock)
        coordinator.post = post

        coordinator.start()

        expect(viewMock.didCallShowLoading).to(beTrue())
    }

    /// Show the share sheet
    ///
    func testShowShareSheet() {
        let button = UIView()
        let post: ReaderPost = ReaderPostBuilder().build()
        let serviceMock = ReaderPostServiceMock()
        let viewMock = ReaderDetailViewMock()
        let postSharingControllerMock = PostSharingControllerMock()
        let coordinator = ReaderDetailCoordinator(readerPostService: serviceMock, sharingController: postSharingControllerMock, view: viewMock)
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
        let coordinator = ReaderDetailCoordinator(readerPostService: serviceMock, sharingController: postSharingControllerMock, view: viewMock)
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
        let coordinator = ReaderDetailCoordinator(readerPostService: serviceMock, sharingController: postSharingControllerMock, view: viewMock)
        let navigationControllerMock = UINavigationControllerMock()
        viewMock.navigationController = navigationControllerMock
        coordinator.post = post

        coordinator.didTapTagButton()

        expect(navigationControllerMock.didCallPushViewControllerWith).toEventually(beAKindOf(ReaderStreamViewController.self))
    }

    /// Present an image in the view controller
    ///
    func testShowPresentImage() {
        let post: ReaderPost = ReaderPostBuilder().build()
        let serviceMock = ReaderPostServiceMock()
        let viewMock = ReaderDetailViewMock()
        let coordinator = ReaderDetailCoordinator(readerPostService: serviceMock, view: viewMock)
        coordinator.post = post

        coordinator.handle(URL(string: "https://wordpress.com/image.png")!)

        expect(viewMock.didCallPresentWith).to(beAKindOf(WPImageViewController.self))
    }

    /// Present an URL in a new Reader Detail screen
    ///
    func testShowPresentURL() {
        let post: ReaderPost = ReaderPostBuilder().build()
        let serviceMock = ReaderPostServiceMock()
        let viewMock = ReaderDetailViewMock()
        let coordinator = ReaderDetailCoordinator(readerPostService: serviceMock, view: viewMock)
        coordinator.post = post
        let navigationControllerMock = UINavigationControllerMock()
        viewMock.navigationController = navigationControllerMock

        coordinator.handle(URL(string: "https://wpmobilep2.wordpress.com/2020/06/01/hello-test/")!)

        expect(navigationControllerMock.didCallPushViewControllerWith).to(beAKindOf(ReaderDetailViewController.self))
    }

    /// Present an URL in a webview controller
    ///
    func testShowPresentURLInWebViewController() {
        let post: ReaderPost = ReaderPostBuilder().build()
        let serviceMock = ReaderPostServiceMock()
        let viewMock = ReaderDetailViewMock()
        let coordinator = ReaderDetailCoordinator(readerPostService: serviceMock, view: viewMock)
        coordinator.post = post

        coordinator.handle(URL(string: "https://wordpress.com")!)

        let presentedViewController = (viewMock.didCallPresentWith as? UINavigationController)?.viewControllers.first
        expect(presentedViewController).to(beAKindOf(WebKitViewController.self))
    }

    /// Tell the view to scroll when URL is a hash link
    ///
    func testScrollWhenUrlIsHash() {
        let post: ReaderPost = ReaderPostBuilder().build()
        let serviceMock = ReaderPostServiceMock()
        let viewMock = ReaderDetailViewMock()
        let coordinator = ReaderDetailCoordinator(readerPostService: serviceMock, view: viewMock)
        coordinator.post = post

        coordinator.handle(URL(string: "https://wordpress.com#hash")!)

        expect(viewMock.didCallScrollToWith).to(equal("hash"))
    }

    func testExtractCommentIDFromPostURL() {
        let postURL = URL(string: "https://example.wordpress.com/2014/07/24/post-title/#comment-10")
        let serviceMock = ReaderPostServiceMock()
        let viewMock = ReaderDetailViewMock()
        let coordinator = ReaderDetailCoordinator(readerPostService: serviceMock, view: viewMock)
        coordinator.postURL = postURL

        expect(coordinator.commentID).to(equal(10))
    }
}

// MARK: - Private Helpers

private class ReaderPostServiceMock: ReaderPostService {
    var didCallFetchPostWithPostID: UInt?
    var didCallFetchPostWithSiteID: UInt?
    var didCallFetchPostWithIsFeed: Bool?
    var didCallFetchWithURL: URL?

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

    override func fetchPost(at postURL: URL!, success: ((ReaderPost?) -> Void)!, failure: ((Error?) -> Void)!) {
        didCallFetchWithURL = postURL

        guard !forceError else {
            failure(nil)
            return
        }
    }
}

private class ReaderDetailViewMock: UIViewController, ReaderDetailView {
    var didCallRenderWithPost: ReaderPost?
    var didCallShowError = false
    var didCallPresentWith: UIViewController?
    var didCallShowLoading = false
    var didCallShowErrorWithWebAction = false
    var didCallScrollToWith: String?

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

    func showErrorWithWebAction() {
        didCallShowErrorWithWebAction = true
    }

    func showLoading() {
        didCallShowLoading = true
    }

    func scroll(to: String) {
        didCallScrollToWith = to
    }

    func updateHeader() { }

    func updateLikes(with avatarURLStrings: [String], totalLikes: Int) { }

    func updateSelfLike(with avatarURLString: String?) { }

    func updateComments(_ comments: [Comment], totalComments: Int) { }

    func renderRelatedPosts(_ posts: [RemoteReaderSimplePost]) { }

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        didCallPresentWith = viewControllerToPresent
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
