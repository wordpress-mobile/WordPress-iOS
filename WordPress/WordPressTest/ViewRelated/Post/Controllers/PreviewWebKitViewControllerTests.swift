import XCTest
@testable import WordPress

class PreviewWebKitViewControllerTests: XCTestCase {

    private var rootWindow: UIWindow!
    private var context: NSManagedObjectContext!
    private var navController = UINavigationController()

    override func setUp() {
        super.setUp()
        context = TestContextManager().mainContext

        rootWindow = UIWindow(frame: UIScreen.main.bounds)
        rootWindow.isHidden = false
        rootWindow.rootViewController = navController
    }

    override func tearDown() {
        super.tearDown()
        context = nil
        ContextManager.overrideSharedInstance(nil)
    }

    func testMissingPermalink() {
        let post = PostBuilder(context).drafted().build()

        let vc = PreviewWebKitViewController(post: post, previewURL: nil, source: "test_missing_permalink")
        XCTAssertEqual(vc.url!.absoluteString, "about:blank", "Should load blank page when no permalink is available")
    }

    func testDraftToolbarItems() {

        let post = PostBuilder(context).drafted().build()
        post.permaLink = "http://example.com/"

        let vc = PreviewWebKitViewController(post: post, previewURL: nil, source: "test_draft_toolbar")
        let items = vc.toolbarItems(linkBehavior: vc.linkBehavior)

        XCTAssertTrue(items.contains(vc.publishButton), "Preview toolbar for draft should contain publish button.")
        XCTAssertFalse(items.contains(vc.safariButton),
                       "Preview toolbar for draft should not contain Safari button.")
        XCTAssertFalse(items.contains(vc.backButton), "Preview toolbar for draft should not contain back button.")
        XCTAssertFalse(items.contains(vc.forwardButton), "Preview toolbar for draft should not contain foward button.")
        XCTAssertTrue(items.contains(vc.previewButton), "Preview toolbar for draft should contain preview button.")
    }

    func testPublishedToolbarItems() {

        let post = PostBuilder(context).published().build()
        post.permaLink = "http://example.com/"

        let vc = PreviewWebKitViewController(post: post, previewURL: nil, source: "test_published_toolbar")
        let items = vc.toolbarItems(linkBehavior: vc.linkBehavior)

        XCTAssertTrue(items.contains(vc.shareButton), "Preview toolbar for post should contain share button.")
        XCTAssertTrue(items.contains(vc.safariButton), "Preview toolbar for post should contain Safari button.")
        XCTAssertFalse(items.contains(vc.backButton), "Preview toolbar for post should not contain back button.")
        XCTAssertFalse(items.contains(vc.forwardButton), "Preview toolbar for post should not contain forward button.")
        XCTAssertTrue(items.contains(vc.previewButton), "Preview toolbar for post should contain preview button.")
    }

    func testSitePageToolbarItems() {

        let page = PageBuilder(context).build()
        page.permaLink = "http://example.com/"

        let vc = PreviewWebKitViewController(post: page, previewURL: nil, source: "test_site_page")
        let items = vc.toolbarItems(linkBehavior: vc.linkBehavior)

        XCTAssertFalse(items.contains(vc.publishButton), "Preview toolbar for page should not contain publish button.")
        XCTAssertTrue(items.contains(vc.safariButton), "Preview toolbar for page should contain Safari button.")
        XCTAssertTrue(items.contains(vc.backButton), "Preview toolbar for page should contain back button.")
        XCTAssertTrue(items.contains(vc.forwardButton), "Preview toolbar for page should contain forward button.")
        XCTAssertTrue(items.contains(vc.previewButton), "Preview toolbar for page should contain preview button.")
    }

    func testToolbarItemsWithDefaultConfiguration() {
        let config = WebViewControllerConfiguration(url: URL(string: "https://example.com"))
        let vc = PreviewWebKitViewController(configuration: config)
        let items = vc.toolbarItems(linkBehavior: vc.linkBehavior)

        XCTAssertFalse(items.contains(vc.publishButton), "Preview toolbar for page should not contain publish button.")
        XCTAssertTrue(items.contains(vc.safariButton), "Preview toolbar for page should contain Safari button.")
        XCTAssertTrue(items.contains(vc.backButton), "Preview toolbar for page should contain back button.")
        XCTAssertTrue(items.contains(vc.forwardButton), "Preview toolbar for page should contain forward button.")
        XCTAssertTrue(items.contains(vc.previewButton), "Preview toolbar for page should contain preview button.")
    }
}
