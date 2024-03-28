import XCTest
@testable import WordPress

class PreviewWebKitViewControllerTests: CoreDataTestCase {

    private var rootWindow: UIWindow!
    private var navController = UINavigationController()

    override func setUp() {
        super.setUp()
        rootWindow = UIWindow(frame: UIScreen.main.bounds)
        rootWindow.isHidden = false
        rootWindow.rootViewController = navController
    }

    func testMissingPermalink() {
        let post = PostBuilder(mainContext).drafted().build()

        let vc = PreviewWebKitViewController(post: post, previewURL: nil, source: "test_missing_permalink")
        XCTAssertEqual(vc.url!.absoluteString, "about:blank", "Should load blank page when no permalink is available")
    }

    func testDraftToolbarItems() {

        let post = PostBuilder(mainContext).drafted().build()
        post.permaLink = "http://example.com/"

        let vc = PreviewWebKitViewController(post: post, previewURL: nil, source: "test_draft_toolbar")
        let items = vc.toolbarItems(linkBehavior: vc.linkBehavior)

        XCTAssertFalse(items.contains(vc.safariButton),
                       "Preview toolbar for draft should not contain Safari button.")
        XCTAssertFalse(items.contains(vc.backButton), "Preview toolbar for draft should not contain back button.")
        XCTAssertFalse(items.contains(vc.forwardButton), "Preview toolbar for draft should not contain foward button.")
        XCTAssertTrue(items.contains(vc.previewButton), "Preview toolbar for draft should contain preview button.")
    }

    func testPublishedToolbarItems() {

        let post = PostBuilder(mainContext).published().build()
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

        let page = PageBuilder(mainContext).build()
        page.permaLink = "http://example.com/"

        let vc = PreviewWebKitViewController(post: page, previewURL: nil, source: "test_site_page")
        let items = vc.toolbarItems(linkBehavior: vc.linkBehavior)

        XCTAssertTrue(items.contains(vc.safariButton), "Preview toolbar for page should contain Safari button.")
        XCTAssertTrue(items.contains(vc.backButton), "Preview toolbar for page should contain back button.")
        XCTAssertTrue(items.contains(vc.forwardButton), "Preview toolbar for page should contain forward button.")
        XCTAssertTrue(items.contains(vc.previewButton), "Preview toolbar for page should contain preview button.")
    }

    func testToolbarItemsWithDefaultConfiguration() {
        let config = WebViewControllerConfiguration(url: URL(string: "https://example.com"))
        let vc = PreviewWebKitViewController(configuration: config)
        let items = vc.toolbarItems(linkBehavior: vc.linkBehavior)

        XCTAssertTrue(items.contains(vc.safariButton), "Preview toolbar for page should contain Safari button.")
        XCTAssertTrue(items.contains(vc.backButton), "Preview toolbar for page should contain back button.")
        XCTAssertTrue(items.contains(vc.forwardButton), "Preview toolbar for page should contain forward button.")
        XCTAssertTrue(items.contains(vc.previewButton), "Preview toolbar for page should contain preview button.")
    }
}
