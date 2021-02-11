import AutomatticTracks
import Foundation
import WordPressKit

class AtomicAuthenticationService {

    let remote: AtomicAuthenticationServiceRemote
    fileprivate let context = ContextManager.sharedInstance().mainContext

    init(remote: AtomicAuthenticationServiceRemote) {
        self.remote = remote
    }

    convenience init(account: WPAccount) {
        let wpComRestApi = account.wordPressComRestV2Api
        let remote = AtomicAuthenticationServiceRemote(wordPressComRestApi: wpComRestApi)

        self.init(remote: remote)
    }

    func getAuthCookie(
        siteID: Int,
        success: @escaping (_ cookie: HTTPCookie) -> Void,
        failure: @escaping (Error) -> Void) {

        remote.getAuthCookie(siteID: siteID, success: success, failure: failure)
    }

    func loadAuthCookies(
        into cookieJar: CookieJar,
        username: String,
        siteID: Int,
        success: @escaping () -> Void,
        failure: @escaping (Error) -> Void) {

        cookieJar.hasWordPressComAuthCookie(
            username: username,
            atomicSite: true) { hasCookie in

                guard !hasCookie else {
                    success()
                    return
                }

                self.getAuthCookie(siteID: siteID, success: { cookies in
                    cookieJar.setCookies([cookies]) {
                        success()
                    }
                }) { error in
                    // Make sure this error scenario isn't silently ignored.
                    WordPressAppDelegate.crashLogging?.logError(error)

                    // Even if getting the auth cookies fail, we'll still try to load the URL
                    // so that the user sees a reasonable error situation on screen.
                    // We could opt to create a special screen but for now I'd rather users report
                    // the issue when it happens.
                    failure(error)
                }
        }
    }
}
