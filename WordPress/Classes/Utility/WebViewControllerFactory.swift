import UIKit

class WebViewControllerFactory: NSObject {
    @available(*, unavailable)
    override init() {
    }

    static func controller(configuration: WebViewControllerConfiguration) -> UIViewController {
        let controller = WPWebViewController()
        controller.url = configuration.url
        controller.optionsButton = configuration.optionsButton
        controller.secureInteraction = configuration.secureInteraction
        controller.addsWPComReferrer = configuration.secureInteraction
        controller.authenticator = configuration.authenticator
        return controller
    }

    static func controller(url: URL) -> UIViewController {
        let configuration = WebViewControllerConfiguration(url: url)
        return controller(configuration: configuration)
    }

    static func controller(url: URL, blog: Blog) -> UIViewController {
        let configuration = WebViewControllerConfiguration(url: url)
        configuration.authenticate(blog: blog)
        return controller(configuration: configuration)
    }

    static func controller(url: URL, account: WPAccount) -> UIViewController {
        let configuration = WebViewControllerConfiguration(url: url)
        configuration.authenticate(account: account)
        return controller(configuration: configuration)
    }

    static func controllerAuthenticatedWithDefaultAccount(url: URL) -> UIViewController {
        let configuration = WebViewControllerConfiguration(url: url)
        configuration.authenticateWithDefaultAccount()
        return controller(configuration: configuration)
    }

}
