import UIKit
import WebKit
import WordPressData

class WebViewControllerConfiguration: NSObject {
    @objc var url: URL?
    @objc var optionsButton: UIBarButtonItem?
    @objc var secureInteraction = false
    @objc var addsWPComReferrer = false
    @objc var displayStatusInNavigationBar = true
    @objc var analyticsSource: String?

    /// Opens any new pages in Safari. Otherwise, a new web view will be opened
    var opensNewInSafari = false

    /// Lets the web view fill the screen, so the page scrolls under the bars above and below it instead of
    /// stopping at them.
    ///
    /// What sits below is the screen's business, not this flag's: the home indicator, and whatever else the
    /// presenting controller keeps down there, such as a tab bar.
    ///
    /// The page's own content stays clear of all of it: the web view's scroll view insets it.
    var ignoresSafeArea = false

    /// The behavior to use for allowing links to be loaded by the web view based
    var linkBehavior = LinkBehavior.all
    @objc var customTitle: String?
    @objc var authenticator: RequestAuthenticator?
    @objc weak var navigationDelegate: WebNavigationDelegate?
    var onClose: (() -> Void)?

    @objc init(url: URL?) {
        self.url = url
        super.init()
    }

    @objc func authenticate(blog: Blog) {
        self.authenticator = RequestAuthenticator(blog: blog)
    }

    @objc func authenticate(account: WPAccount) {
        self.authenticator = RequestAuthenticator(account: account)
    }

    @objc func authenticateWithDefaultAccount() {
        guard let account = try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext) else {
            return
        }
        authenticate(account: account)
    }
}
