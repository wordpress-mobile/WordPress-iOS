import UIKit

class WebViewControllerConfiguration: NSObject {
    @objc var url: URL
    @objc var optionsButton: UIBarButtonItem?
    @objc var secureInteraction = false
    @objc var addsWPComReferrer = false
    @objc var addsHideMasterbarParameters = true
    @objc var customTitle: String?
    @objc var authenticator: WebViewAuthenticator?
    @objc weak var navigationDelegate: WebNavigationDelegate?

    @objc init(url: URL) {
        self.url = url
        super.init()
    }

    @objc func authenticate(blog: Blog) {
        self.authenticator = WebViewAuthenticator(blog: blog)
    }

    @objc func authenticate(account: WPAccount) {
        self.authenticator = WebViewAuthenticator(account: account)
    }

    @objc func authenticateWithDefaultAccount() {
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        guard let account = service.defaultWordPressComAccount() else {
            return
        }
        authenticate(account: account)
    }
}
