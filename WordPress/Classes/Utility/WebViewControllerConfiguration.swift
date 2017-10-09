import UIKit

class WebViewControllerConfiguration: NSObject {
    var url: URL
    var optionsButton: UIBarButtonItem?
    var secureInteraction: Bool = false
    var addsWPComReferrer: Bool = false
    var authenticator: WebViewAuthenticator?

    init(url: URL) {
        self.url = url
        super.init()
    }

    func authenticate(blog: Blog) {
        self.authenticator = WebViewAuthenticator(blog: blog)
    }

    func authenticate(account: WPAccount) {
        self.authenticator = WebViewAuthenticator(account: account)
    }

    func authenticateWithDefaultAccount() {
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        guard let account = service.defaultWordPressComAccount() else {
            return
        }
        authenticate(account: account)
    }
}
