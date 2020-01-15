import UIKit
import WebKit

class WebViewControllerConfiguration: NSObject {
    @objc var url: URL
    @objc var optionsButton: UIBarButtonItem?
    @objc var secureInteraction = false
    @objc var addsWPComReferrer = false
    @objc var addsHideMasterbarParameters = true

    /// Opens any new pages in Safari. Otherwise, a new web view will be opened
    var opensNewInSafari = false

    /// The behavior to use for allowing links to be loaded by the web view based
    var linkBehavior = LinkBehavior.all
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
