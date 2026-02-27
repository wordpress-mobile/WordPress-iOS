import XCTest

@testable import WordPress
@testable import WordPressData

class ReaderDetailCoordinatorTests: CoreDataTestCase {

    /// Given a post ID, site ID and isFeed fetches the post from the service
    ///
    func testRetrieveAReaderPostWhenSiteAndPostAreGiven() {
        let serviceMock = ReaderPostServiceMock()
        let viewMock = ReaderDetailViewMock()
        let coordinator = ReaderDetailCoordinator(readerPostService: serviceMock, view: viewMock)
        coordinator.set(postID: 1, siteID: 2, isFeed: true)

        coordinator.start()

        XCTAssertEqual(serviceMock.didCallFetchPostWithPostID, 1)
        XCTAssertEqual(serviceMock.didCallFetchPostWithSiteID, 2)
        XCTAssertEqual(serviceMock.didCallFetchPostWithIsFeed, true)
    }

    /// Inform the view to render a post after it is fetched
    ///
    func testUpdateViewWithRetrievedPost() {
        let post = makeReaderPost()
        let serviceMock = ReaderPostServiceMock()
        serviceMock.returnPost = post
        let viewMock = ReaderDetailViewMock()
        let coordinator = ReaderDetailCoordinator(readerPostService: serviceMock, view: viewMock)
        coordinator.set(postID: 1, siteID: 2, isFeed: false)

        coordinator.start()

        XCTAssertEqual(viewMock.didCallRenderWithPost, post)
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

        XCTAssertTrue(viewMock.didCallShowError)
    }

    /// If a post is given, do not call the servce and render the content right away
    ///
    func testGivenAPostRenderItRightAway() {
        let post = makeReaderPost()
        let serviceMock = ReaderPostServiceMock()
        let viewMock = ReaderDetailViewMock()
        let coordinator = ReaderDetailCoordinator(readerPostService: serviceMock, view: viewMock)
        coordinator.post = post

        coordinator.start()

        XCTAssertEqual(viewMock.didCallRenderWithPost, post)
        XCTAssertNil(serviceMock.didCallFetchPostWithPostID)
    }

    /// Tell the view to show a loading indicator when start is called
    ///
    func testStartCallsTheViewToShowLoader() {
        let post = makeReaderPost()
        let serviceMock = ReaderPostServiceMock()
        let viewMock = ReaderDetailViewMock()
        let coordinator = ReaderDetailCoordinator(readerPostService: serviceMock, view: viewMock)
        coordinator.post = post

        coordinator.start()

        XCTAssertTrue(viewMock.didCallShowLoading)
    }

    /// Show the share sheet
    ///
    func testShowShareSheet() {
        let button = UIView()
        let post = makeReaderPost()
        let serviceMock = ReaderPostServiceMock()
        let viewMock = ReaderDetailViewMock()
        let postSharingControllerMock = PostSharingControllerMock()
        let coordinator = ReaderDetailCoordinator(readerPostService: serviceMock, sharingController: postSharingControllerMock, view: viewMock)
        coordinator.post = post

        coordinator.share(fromView: button)

        XCTAssertEqual(postSharingControllerMock.didCallShareReaderPostWith, post)
        if let view = postSharingControllerMock.didCallShareReaderPostWithView as? UIView {
            XCTAssertEqual(view, button)
        } else {
            XCTFail("`postSharingControllerMock.didCallShareReaderPostWithView` should equal .view(button)")
        }
        XCTAssertEqual(postSharingControllerMock.didCallShareReaderPostWithViewController, viewMock)
    }

    /// Present an image in the view controller
    ///
    func testShowPresentImage() {
        let post = makeReaderPost()
        let serviceMock = ReaderPostServiceMock()
        let viewMock = ReaderDetailViewMock()
        let coordinator = ReaderDetailCoordinator(readerPostService: serviceMock, view: viewMock)
        coordinator.post = post

        coordinator.handle(URL(string: "https://wordpress.com/image.png")!)

        XCTAssertTrue(viewMock.didCallPresentWith is LightboxViewController)
    }

    /// Present an URL in a webview controller
    ///
    func testShowPresentURLInWebViewController() {
        let post = makeReaderPost()
        let serviceMock = ReaderPostServiceMock()
        let viewMock = ReaderDetailViewMock()
        let coordinator = ReaderDetailCoordinator(readerPostService: serviceMock, view: viewMock)
        coordinator.post = post

        coordinator.handle(URL(string: "https://wordpress.com")!)

        let presentedViewController = (viewMock.didCallPresentWith as? UINavigationController)?.viewControllers.first
        XCTAssertTrue(presentedViewController is WebKitViewController)
    }

    /// Tell the view to scroll when URL is a hash link
    ///
    func testScrollWhenUrlIsHash() {
        let post = makeReaderPost()
        let serviceMock = ReaderPostServiceMock()
        let viewMock = ReaderDetailViewMock()
        let coordinator = ReaderDetailCoordinator(readerPostService: serviceMock, view: viewMock)
        coordinator.post = post

        coordinator.handle(URL(string: "https://wordpress.com#hash")!)

        XCTAssertEqual(viewMock.didCallScrollToWith, "hash")
    }

    func testExtractCommentIDFromPostURL() {
        let postURL = URL(string: "https://example.wordpress.com/2014/07/24/post-title/#comment-10")
        let serviceMock = ReaderPostServiceMock()
        let viewMock = ReaderDetailViewMock()
        let coordinator = ReaderDetailCoordinator(readerPostService: serviceMock, view: viewMock)
        coordinator.postURL = postURL

        XCTAssertEqual(coordinator.commentID, 10)
    }

    func makeReaderPost() -> ReaderPost {
        ReaderPostBuilder(mainContext).build()
    }
}

// MARK: - Private Helpers

private class ReaderPostServiceMock: ReaderPostService {
    var didCallFetchPostWithPostID: UInt?
    var didCallFetchPostWithSiteID: UInt?
    var didCallFetchPostWithIsFeed: Bool?

    /// The post that should be returned by the mock
    var returnPost: ReaderPost?

    /// If we want to force an error
    var forceError = false

    init() {
        super.init(coreDataStack: ContextManager.forTesting())
    }

    override func fetchPost(_ postID: UInt, forSite siteID: UInt, isFeed: Bool, success: ((ReaderPost?) -> Void)!, failure: ((Error?) -> Void)!) {
        didCallFetchPostWithPostID = postID
        didCallFetchPostWithSiteID = siteID
        didCallFetchPostWithIsFeed = isFeed

        guard !forceError else {
            failure(nil)
            return
        }

        guard let returnPost else {
            return
        }

        success(returnPost)
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

    func showError(subtitle: String?) {
        didCallShowError = true
    }

    func showErrorWithWebAction(error: (any Error)?) {
        didCallShowErrorWithWebAction = true
    }

    func showLoading() {
        didCallShowLoading = true
    }

    func scroll(to: String) {
        didCallScrollToWith = to
    }

    func updateHeader() { }

    func updateLikesView(with viewModel: ReaderDetailLikesViewModel) {}

    func updateComments(_ comments: [Comment], totalComments: Int) { }

    func renderRelatedPosts(_ posts: [RemoteReaderSimplePost]) { }

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        didCallPresentWith = viewControllerToPresent
    }
}

private class PostSharingControllerMock: PostSharingController {
    var didCallShareReaderPostWith: ReaderPost?
    var didCallShareReaderPostWithView: UIPopoverPresentationControllerSourceItem?
    var didCallShareReaderPostWithViewController: UIViewController?

    override func shareReaderPost(_ post: ReaderPost, fromAnchor anchor: UIPopoverPresentationControllerSourceItem, inViewController viewController: UIViewController) {
        didCallShareReaderPostWith = post
        didCallShareReaderPostWithView = anchor
        didCallShareReaderPostWithViewController = viewController
    }
}
