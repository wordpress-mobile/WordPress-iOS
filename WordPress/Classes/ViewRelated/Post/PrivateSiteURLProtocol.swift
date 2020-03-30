import Foundation
import AutomatticTracks

extension PrivateSiteURLProtocol {

    enum Error: Swift.Error {
        case cannotBreakDownURLIntoComponents(url: URL)
        case cannotFindWPContentInPhotonPath(components: URLComponents)
        case cannotCreateAtomicProxyURL(components: URLComponents)
    }

    static let photonHost = "i0.wp.com"

    private static func isPhoton(url: URL) -> Bool {
        return url.host == photonHost
    }

    static func request(
        for url: URL,
        siteID: Int,
        isAtomic: Bool,
        onComplete provide: @escaping (URLRequest) -> ()) {

        if urlGoes(toWPComSite: url) {
            if isAtomic {
                requestForPrivateAtomicSite(for: url, siteID: siteID, onComplete: provide)
            } else {
                let request = requestForPrivateSite(from: url)
                provide(request)
            }
        } else if isAtomic && isPhoton(url: url) {
            requestForPrivateAtomicSiteThroughPhoton(for: url, siteID: siteID, onComplete: provide)
        } else {
            let request = URLRequest(url: url)
            provide(request)
        }
    }

    /// Photon URLs are currently not working for private atomic sites, so this is a workaround
    /// to replace those URLs with working URLs.
    ///
    /// To know whether you can remove this method, try requesting the photon URL from an
    /// atomic private site.  If it works then you can remove this workaround logic.
    ///
    static func requestForPrivateAtomicSiteThroughPhoton(
        for url: URL,
        siteID: Int,
        onComplete provide: @escaping (URLRequest) -> ()) {

        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            CrashLogging.logError(Error.cannotBreakDownURLIntoComponents(url: url))
            provide(URLRequest(url: url))
            return
        }

        guard let wpContentRange = components.path.range(of: "/wp-content") else {
            CrashLogging.logError(Error.cannotFindWPContentInPhotonPath(components: components))
            provide(URLRequest(url: url))
            return
        }

        let contentPath = components.path[wpContentRange.lowerBound ..< components.path.endIndex]

        components.scheme = "https"
        components.host = "public-api.wordpress.com"
        components.path = "/wpcom/v2/sites/\(siteID)/atomic-auth-proxy/file\(contentPath)"

        guard let finalURL = components.url else {
            CrashLogging.logError(Error.cannotCreateAtomicProxyURL(components: components))
            provide(URLRequest(url: url))
            return
        }

        let request = URLRequest(url: finalURL)
        provide(request)
    }

    static func requestForPrivateAtomicSite(
        for url: URL,
        siteID: Int,
        onComplete provide: @escaping (URLRequest) -> ()) {

        guard !PrivateSiteURLProtocol.urlGoes(toWPComSite: url),
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            let urlComponent = components.url,
            let account = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext).defaultWordPressComAccount(),
            let bearerToken = account.authToken else {
                return provide(URLRequest(url: url))
        }

        let authenticationService = AtomicAuthenticationService(account: account)
        let cookieJar = HTTPCookieStorage.shared

        // Just in case, enforce HTTPs
        components.scheme = "https"

        var request = URLRequest(url: urlComponent)
        request.addValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

        authenticationService.loadAuthCookies(into: cookieJar, username: account.username, siteID: siteID, success: {
            return provide(request)
        }) { error in
            return provide(request)
        }
    }
}
