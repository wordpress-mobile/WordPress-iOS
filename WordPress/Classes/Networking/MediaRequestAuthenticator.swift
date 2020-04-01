import AutomatticTracks
import Foundation

fileprivate let photonHost = "i0.wp.com"

extension URL {
    func isHostedAtWPCom() -> Bool {
        // I don't think this method should check for HTTPs here, and we'd rather test
        // that separately.  But since this code is basically a migration, I'm leaving
        // the check for now to avoid breaking things.
        return scheme == "https" && host?.hasSuffix(".wordpress.com") ?? false
    }

    fileprivate func isPhoton() -> Bool {
        return host == photonHost
    }
}

/// This class takes care of resolving any authentication necessary before
/// requesting media from WP sites (both self-hosted and WP.com).
///
/// This also includes regular and photon URLs.
///
class MediaRequestAuthenticator {

    enum Error: Swift.Error {
        case cannotFindSiteIDForSiteAvailableThroughWPCom(blog: Blog)
        case cannotBreakDownURLIntoComponents(url: URL)
        case cannotCreateAtomicURL(components: URLComponents)
        case cannotCreateAtomicProxyURL(components: URLComponents)
        case cannotCreatePrivateURL(components: URLComponents)
        case cannotFindAuthenticationToken(url: URL)
        case cannotFindWPContentInPhotonPath(components: URLComponents)
    }

    // MARK: - Request Authentication

    /// Pass this method a media URL, and it will handle all the necessary logic to provide the caller
    /// with an authenticated request through the completion closure.
    ///
    /// - Parameters:
    ///     - url: the url for the media.
    ///     - blog: the blog associated with the passed media URL.
    ///     - onComplete: the closure that will be called once authentication is sorted out by this class.
    ///         The request can be executed directly without having to do anything else in terms of
    ///         authentication.
    ///
    func authenticatedRequest(
        for url: URL,
        blog: Blog,
        onComplete provide: @escaping (URLRequest) -> (),
        onFailure fail: @escaping (Error) -> ()) {

        guard blog.isAccessibleThroughWPCom() else {
            let request = URLRequest(url: url)
            provide(request)
            return
        }

        guard let siteID = blog.dotComID?.intValue else {
            fail(Error.cannotFindSiteIDForSiteAvailableThroughWPCom(blog: blog))
            return
        }

        authenticatedWPComRequest(
            for: url,
            siteID: siteID,
            inPrivateBlog: blog.isPrivate(),
            inAtomicBlog: blog.isAtomic(),
            onComplete: provide)
    }

    /// Same as above, but this method authenticates WPCom hosted requests only.
    ///
    /// - Parameters:
    ///     - url: the url for the media.
    ///     - siteID: the ID of the site associated with this media.  It may not be the host though
    ///         as can be the case with photon URLs that are hosted elsewhere.
    ///     - inPrivateBlog: whether the owning site is private.
    ///     - inAtomicBlog: whether the owning site is atomic.  This is relevant since atomic authentication
    ///         is not standard.
    ///     - onComplete: the closure that will be called once authentication is sorted out by this class.
    ///         The request can be executed directly without having to do anything else in terms of
    ///         authentication.
    ///
    func authenticatedWPComRequest(
        for url: URL,
        siteID: Int,
        inPrivateBlog: Bool,
        inAtomicBlog: Bool,
        onComplete provide: @escaping (URLRequest) -> ()) {

        guard inPrivateBlog else {
            let request = URLRequest(url: url)
            provide(request)
            return
        }

        if url.isHostedAtWPCom() {
            if inAtomicBlog {
                authenticatedRequestForPrivateAtomicSite(for: url, siteID: siteID, onComplete: provide)
            } else {
                let request = authenticatedRequestForPrivateSite(for: url)
                provide(request)
            }
        } else if inAtomicBlog && url.isPhoton() {
            authenticatedRequestForPrivateAtomicSiteThroughPhoton(for: url, siteID: siteID, onComplete: provide)
        } else {
            let request = URLRequest(url: url)
            provide(request)
        }
    }

    // MARK: - Request Authentication: Specific Scenarios

    func authenticatedRequestForPrivateSite(for url: URL) -> URLRequest {
        guard !url.isHostedAtWPCom(),
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            let account = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext).defaultWordPressComAccount(),
            let authToken = account.authToken else {
                return URLRequest(url: url)
        }

        // Just in case, enforce HTTPs
        components.scheme = "https"

        guard let finalURL = components.url else {
            CrashLogging.logError(Error.cannotCreatePrivateURL(components: components))
            return URLRequest(url: url)
        }

        let request = tokenAuthenticatedWPComRequest(for: finalURL, authToken: authToken)
        return request
    }

    private func authenticatedRequestForPrivateAtomicSite(
        for url: URL,
        siteID: Int,
        onComplete provide: @escaping (URLRequest) -> ()) {

        guard !url.isHostedAtWPCom(),
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            let account = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext).defaultWordPressComAccount(),
            let authToken = account.authToken else {
                return provide(URLRequest(url: url))
        }

        let authenticationService = AtomicAuthenticationService(account: account)
        let cookieJar = HTTPCookieStorage.shared

        // Just in case, enforce HTTPs
        components.scheme = "https"

        guard let finalURL = components.url else {
            CrashLogging.logError(Error.cannotCreateAtomicURL(components: components))
            provide(URLRequest(url: url))
            return
        }

        let request = tokenAuthenticatedWPComRequest(for: finalURL, authToken: authToken)

        authenticationService.loadAuthCookies(into: cookieJar, username: account.username, siteID: siteID, success: {
            return provide(request)
        }) { error in
            return provide(request)
        }
    }

    /// Photon URLs are currently not working for private atomic sites, so this is a workaround
    /// to replace those URLs with working URLs.
    ///
    /// By recommendation of @zieladam we'll be using the Atomic Proxy endpoint for these until
    /// Photon starts working with Atomic Private Sites:
    ///
    /// https://public-api.wordpress.com/wpcom/v2/sites/$siteID/atomic-auth-proxy/file/$wpContentPath
    ///
    /// To know whether you can remove this method, try requesting the photon URL from an
    /// atomic private site.  If it works then you can remove this workaround logic.
    ///
    private func authenticatedRequestForPrivateAtomicSiteThroughPhoton(
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

        guard let request = tokenAuthenticatedWPComRequest(for: finalURL) else {
            CrashLogging.logError(Error.cannotFindAuthenticationToken(url: finalURL))
            provide(URLRequest(url: url))
            return
        }

        provide(request)
    }

    // MARK: - Adding the Auth Token

    private func tokenAuthenticatedWPComRequest(for url: URL) -> URLRequest? {
        guard let account = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext).defaultWordPressComAccount(),
            let authToken = account.authToken else {
                return nil
        }

        return tokenAuthenticatedWPComRequest(for: url, authToken: authToken)
    }

    private func tokenAuthenticatedWPComRequest(for url: URL, authToken: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        return request
    }
}
