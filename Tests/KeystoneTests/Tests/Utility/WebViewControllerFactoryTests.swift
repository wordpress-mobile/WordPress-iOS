import Testing
import UIKit

@testable import WordPress

@MainActor
struct WebViewControllerFactoryTests {

    @Test func readerPostControllerWrapsAWebViewInANavigationController() throws {
        let url = try #require(URL(string: "https://example.wordpress.com/2026/11/12/post/"))

        let controller = WebViewControllerFactory.readerPostController(url: url, source: "test")

        let navigationController = try #require(controller as? UINavigationController)
        let webViewController = try #require(navigationController.viewControllers.first as? WebKitViewController)
        #expect(webViewController.url == url)
        #expect(webViewController.addsWPComReferrer)
        #expect(webViewController.analyticsSource == "test")
    }
}
