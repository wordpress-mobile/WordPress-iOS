import Foundation
import WordPressKit

class AtomicAuthenticationService {
    let remote: AtomicAuthenticationServiceRemote
    fileprivate let context = ContextManager.sharedInstance().mainContext

    init(remote: AtomicAuthenticationServiceRemote) {
        self.remote = remote
    }

    func getAuthCookie(
        siteID: Int,
        success: @escaping (_ cookie: HTTPCookie) -> Void,
        failure: @escaping (Error) -> Void) {

        remote.getAuthCookie(siteID: siteID, success: success, failure: failure)
    }
}
