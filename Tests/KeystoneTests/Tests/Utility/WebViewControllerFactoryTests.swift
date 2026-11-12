import SafariServices
import UIKit
import XCTest

@testable import WordPress
@testable import WordPressData

/// XCTest rather than Swift Testing: these tests set the process-wide default WordPress.com account and shared
/// context manager, which would race with Swift Testing suites running in parallel. XCTest suites run in their own
/// serial phase.
final class WebViewControllerFactoryTests: CoreDataTestCase {
    private var previousDefaultDotComUUID: String?
    private let url = URL(string: "https://example.wordpress.com/2026/11/12/post/")!

    override func setUp() {
        super.setUp()
        contextManager.useAsSharedInstance(untilTestFinished: self)
        previousDefaultDotComUUID = UserSettings.defaultDotComUUID
        UserSettings.defaultDotComUUID = nil
    }

    override func tearDown() {
        UserSettings.defaultDotComUUID = previousDefaultDotComUUID
        super.tearDown()
    }

    // MARK: - readerPostController

    func testReaderPostControllerIsSignedInWithTheDefaultAccount() throws {
        makeDefaultAccount()

        let webViewController = try webViewController(
            in: WebViewControllerFactory.readerPostController(url: url, source: "test")
        )

        XCTAssertNotNil(webViewController.authenticator)
        XCTAssertEqual(webViewController.url, url)
        XCTAssertTrue(webViewController.addsWPComReferrer)
        XCTAssertEqual(webViewController.analyticsSource, "test")
    }

    func testReaderPostControllerWithoutAnAccountIsNotSignedIn() throws {
        let webViewController = try webViewController(
            in: WebViewControllerFactory.readerPostController(url: url, source: "test")
        )

        XCTAssertNil(webViewController.authenticator)
        XCTAssertEqual(webViewController.url, url)
    }

    // MARK: - readerPostBrowserController

    func testWordPressComPostOpensInTheSignedInWebView() throws {
        makeDefaultAccount()
        let post = makePost(isWPCom: true, isBlogPrivate: false)

        let controller = WebViewControllerFactory.readerPostBrowserController(post: post, url: url, source: "test")

        XCTAssertNotNil(try webViewController(in: controller).authenticator)
    }

    func testPrivatePostOpensInTheSignedInWebView() throws {
        makeDefaultAccount()
        let post = makePost(isWPCom: false, isBlogPrivate: true)

        let controller = WebViewControllerFactory.readerPostBrowserController(post: post, url: url, source: "test")

        XCTAssertNotNil(try webViewController(in: controller).authenticator)
    }

    func testPublicPostOnAnotherHostOpensInSafari() {
        makeDefaultAccount()
        let post = makePost(isWPCom: false, isBlogPrivate: false)

        let controller = WebViewControllerFactory.readerPostBrowserController(post: post, url: url, source: "test")

        XCTAssertTrue(controller is SFSafariViewController)
    }

    // MARK: - Helpers

    private func makeDefaultAccount() {
        let account = AccountBuilder(mainContext)
            .with(username: "web-view-factory-user")
            .with(authToken: "web-view-factory-token")
            .build()
        UserSettings.defaultDotComUUID = account.uuid
    }

    private func makePost(isWPCom: Bool, isBlogPrivate: Bool) -> ReaderPost {
        let post = ReaderPost(context: mainContext)
        post.isWPCom = isWPCom
        post.isBlogPrivate = isBlogPrivate
        return post
    }

    private func webViewController(in controller: UIViewController) throws -> WebKitViewController {
        let navigationController = try XCTUnwrap(controller as? UINavigationController)
        return try XCTUnwrap(navigationController.viewControllers.first as? WebKitViewController)
    }
}
