import AutomatticTracks
import Foundation
import WordPressData
import WordPressKit

class AtomicAuthenticationService {

    let remote: AtomicAuthenticationServiceRemote

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

    @MainActor
    func loadAuthCookies(into cookieJar: CookieJar, username: String, siteID: Int) async throws {
        guard await !cookieJar.hasWordPressComAuthCookie(username: username, atomicSite: true) else {
            return
        }

        let cookie: HTTPCookie
        do {
            cookie = try await withCheckedThrowingContinuation { continuation in
                getAuthCookie(
                    siteID: siteID,
                    success: { continuation.resume(returning: $0) },
                    failure: { continuation.resume(throwing: $0) })
            }
        } catch {
            // Make sure this error scenario isn't silently ignored.
            WordPressAppDelegate.crashLogging?.logError(error)
            throw error
        }

        await cookieJar.setCookie(cookie)
    }
}
