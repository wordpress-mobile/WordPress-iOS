import UIKit

class WebViewControllerFactory: NSObject {
    @available(*, unavailable)
    override init() {
    }

    @objc static func controller(configuration: WebViewControllerConfiguration) -> UIViewController {
        let controller = WebKitViewController(configuration: configuration)
        return controller
    }

    @objc static func controller(url: URL) -> UIViewController {
        let configuration = WebViewControllerConfiguration(url: url)
        return controller(configuration: configuration)
    }

    @objc static func controller(url: URL, title: String) -> UIViewController {
        let configuration = WebViewControllerConfiguration(url: url)
        configuration.customTitle = title
        return controller(configuration: configuration)
    }

    @objc static func controller(url: URL, blog: Blog) -> UIViewController {
        let configuration = WebViewControllerConfiguration(url: url)
        configuration.authenticate(blog: blog)
        return controller(configuration: configuration)
    }

    @objc static func controller(url: URL, account: WPAccount) -> UIViewController {
        let configuration = WebViewControllerConfiguration(url: url)
        configuration.authenticate(account: account)
        return controller(configuration: configuration)
    }

    @objc static func controllerAuthenticatedWithDefaultAccount(url: URL) -> UIViewController {
        let configuration = WebViewControllerConfiguration(url: url)
        configuration.authenticateWithDefaultAccount()
        return controller(configuration: configuration)
    }

}
