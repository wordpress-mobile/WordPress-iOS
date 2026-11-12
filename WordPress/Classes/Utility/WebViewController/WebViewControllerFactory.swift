import SafariServices
import UIKit
import WebKit
import WordPressData

enum WebViewControllerFactory {
    static func controller(configuration: WebViewControllerConfiguration, source: String) -> WebKitViewController {
        configuration.analyticsSource = source

        let controller = WebKitViewController(configuration: configuration)
        return controller
    }

    static func controller(url: URL, source: String) -> UIViewController {
        let configuration = WebViewControllerConfiguration(url: url)
        return controller(configuration: configuration, source: source)
    }

    static func controller(url: URL, title: String, source: String) -> UIViewController {
        let configuration = WebViewControllerConfiguration(url: url)
        configuration.customTitle = title
        return controller(configuration: configuration, source: source)
    }

    static func controller(
        url: URL,
        blog: Blog,
        source: String,
        withDeviceModes: Bool = false,
        onClose: (() -> Void)? = nil
    ) -> UIViewController {
        let configuration = WebViewControllerConfiguration(url: url)
        configuration.analyticsSource = source
        configuration.authenticate(blog: blog)
        configuration.onClose = onClose
        return withDeviceModes
            ? PreviewWebKitViewController(configuration: configuration)
            : controller(configuration: configuration, source: source)
    }

    static func controller(url: URL, account: WPAccount, source: String) -> UIViewController {
        let configuration = WebViewControllerConfiguration(url: url)
        configuration.authenticate(account: account)
        return controller(configuration: configuration, source: source)
    }

    static func controllerAuthenticatedWithDefaultAccount(url: URL, source: String) -> UIViewController {
        let configuration = WebViewControllerConfiguration(url: url)
        configuration.authenticateWithDefaultAccount()
        return controller(configuration: configuration, source: source)
    }

    /// Opens a Reader post's page for "View in Browser" and "View full post".
    ///
    /// Posts on WordPress.com and posts on private sites open in the signed-in web view (see
    /// `readerPostController(url:source:)`), so private WordPress.com sites such as P2s load instead of showing a
    /// login page. Everything else opens in `SFSafariViewController`: those pages don't need our login, and it keeps
    /// Safari's content blockers, Reader mode and AutoFill.
    ///
    /// - Returns: a view controller, ready to present.
    static func readerPostBrowserController(post: ReaderPost, url: URL, source: String) -> UIViewController {
        guard post.isWPCom || post.isBlogPrivate else {
            return SFSafariViewController(url: url)
        }
        return readerPostController(url: url, source: source)
    }

    /// Opens a Reader post in the in-app web view, signed in with the default WordPress.com account, so posts on
    /// private WordPress.com sites such as P2s load instead of showing a login page.
    ///
    /// `SFSafariViewController` can't do this: it doesn't share Safari's cookies, and the app can't give it any.
    ///
    /// Private sites hosted on Atomic still show their private-site page: they need a separate per-site cookie that
    /// this doesn't request.
    ///
    /// - Returns: a navigation controller, ready to present.
    static func readerPostController(url: URL, source: String) -> UIViewController {
        let configuration = WebViewControllerConfiguration(url: url)
        configuration.authenticateWithDefaultAccount()
        configuration.addsWPComReferrer = true
        return UINavigationController(rootViewController: controller(configuration: configuration, source: source))
    }

    static func controllerWithDefaultAccountAndSecureInteraction(
        url: URL,
        source: String,
        title: String? = nil
    ) -> WebKitViewController {
        let configuration = WebViewControllerConfiguration(url: url)
        configuration.authenticateWithDefaultAccount()
        configuration.secureInteraction = true
        configuration.customTitle = title

        return controller(configuration: configuration, source: source)
    }
}
