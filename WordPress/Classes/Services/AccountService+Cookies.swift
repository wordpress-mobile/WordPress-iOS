import Foundation

extension AccountService {

    /// Loads the default WordPress account's cookies into shared cookie storage.
    ///
    static func loadDefaultAccountCookies() {
        let service = AccountService(managedObjectContext: ContextManager.shared.mainContext)
        guard
            let account = service.defaultWordPressComAccount(),
            let auth = RequestAuthenticator(account: account),
            let url = URL(string: WPComDomain)
        else {
            return
        }
        auth.request(url: url, cookieJar: HTTPCookieStorage.shared) { _ in
            // no op
        }
    }

}
