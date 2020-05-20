import Foundation

fileprivate let photonHost = "i0.wp.com"
fileprivate let secureHttpScheme = "https"
fileprivate let wpComApiHost = "public-api.wordpress.com"

extension URL {
    /// Whether the URL is a Photon URL.
    ///
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

    /// Errors conditions that this class can find.
    ///
    enum Error: Swift.Error {
        case cannotFindSiteIDForSiteAvailableThroughWPCom(blog: Blog)
        case cannotBreakDownURLIntoComponents(url: URL)
        case cannotCreateAtomicURL(components: URLComponents)
        case cannotCreateAtomicProxyURL(components: URLComponents)
        case cannotCreatePrivateURL(components: URLComponents)
        case cannotFindWPContentInPhotonPath(components: URLComponents)
        case failedToLoadAtomicAuthenticationCookies(underlyingError: Swift.Error)
    }

    // MARK: - Request Authentication

    /// Pass this method a media URL and host information, and it will handle all the necessary
    /// logic to provide the caller with an authenticated request through the completion closure.
    ///
    /// - Parameters:
    ///     - url: the url for the media.
    ///     - host: the `MediaHost` for the requested Media.  This is used for authenticating the requests.
    ///     - provide: the closure that will be called once authentication is sorted out by this class.
    ///         The request can be executed directly without having to do anything else in terms of
    ///         authentication.
    ///     - fail: the closure that will be called upon finding an error condition.
    ///
    func authenticatedRequest(
        for url: URL,
        from host: MediaHost,
        onComplete provide: @escaping (URLRequest) -> (),
        onFailure fail: @escaping (Error) -> ()) {

        // We want to make sure we're never sending credentials
        // to a URL that's not safe.
        guard !url.isFileURL || url.isHostedAtWPCom || url.isPhoton() else {
            let request = URLRequest(url: url)
            provide(request)
            return
        }

        switch host {
        case .publicSite:
            fallthrough
        case .publicWPComSite:
            fallthrough
        case .privateSelfHostedSite:
            // The authentication for these is handled elsewhere
            let request = URLRequest(url: url)
            provide(request)
        case .privateWPComSite(let authToken):
            authenticatedRequestForPrivateSite(
                for: url,
                authToken: authToken,
                onComplete: provide,
                onFailure: fail)
        case .privateAtomicWPComSite(let siteID, let username, let authToken):
            if url.isPhoton() {
                authenticatedRequestForPrivateAtomicSiteThroughPhoton(
                    for: url,
                    siteID: siteID,
                    authToken: authToken,
                    onComplete: provide,
                    onFailure: fail)
            } else {
                authenticatedRequestForPrivateAtomicSite(
                    for: url,
                    siteID: siteID,
                    username: username,
                    authToken: authToken,
                    onComplete: provide,
                    onFailure: fail)
            }
        }
    }

    // MARK: - Request Authentication: Specific Scenarios

    /// Authentication for a WPCom private request.
    ///
    /// - Parameters:
    ///     - url: the url for the media.
    ///     - provide: the closure that will be called once authentication is sorted out by this class.
    ///         The request can be executed directly without having to do anything else in terms of
    ///         authentication.
    ///     - fail: the closure that will be called upon finding an error condition.
    ///
    private func authenticatedRequestForPrivateSite(
        for url: URL,
        authToken: String,
        onComplete provide: (URLRequest) -> (),
        onFailure fail: (Error) -> ()) {

        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            fail(Error.cannotBreakDownURLIntoComponents(url: url))
            return
        }

        // Just in case, enforce HTTPs
        components.scheme = secureHttpScheme

        guard let finalURL = components.url else {
            fail(Error.cannotCreatePrivateURL(components: components))
            return
        }

        let request = tokenAuthenticatedWPComRequest(for: finalURL, authToken: authToken)
        provide(request)
    }

    /// Authentication for a WPCom private atomic request.
    ///
    /// - Parameters:
    ///     - url: the url for the media.
    ///     - siteID: the ID of the site that owns this media.
    ///     - provide: the closure that will be called once authentication is sorted out by this class.
    ///         The request can be executed directly without having to do anything else in terms of
    ///         authentication.
    ///     - fail: the closure that will be called upon finding an error condition.
    ///
    private func authenticatedRequestForPrivateAtomicSite(
        for url: URL,
        siteID: Int,
        username: String,
        authToken: String,
        onComplete provide: @escaping (URLRequest) -> (),
        onFailure fail: @escaping (Error) -> ()) {

        guard url.isHostedAtWPCom,
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                provide(URLRequest(url: url))
                return
        }

        guard let account = AccountService(managedObjectContext: ContextManager.shared.mainContext).defaultWordPressComAccount() else {
            provide(URLRequest(url: url))
            return
        }

        let authenticationService = AtomicAuthenticationService(account: account)
        let cookieJar = HTTPCookieStorage.shared

        // Just in case, enforce HTTPs
        components.scheme = secureHttpScheme

        guard let finalURL = components.url else {
            fail(Error.cannotCreateAtomicURL(components: components))
            return
        }

        let request = tokenAuthenticatedWPComRequest(for: finalURL, authToken: authToken)

        authenticationService.loadAuthCookies(into: cookieJar, username: account.username, siteID: siteID, success: {
            provide(request)
        }) { error in
            fail(Error.failedToLoadAtomicAuthenticationCookies(underlyingError: error))
        }
    }

    /// Authentication for a Photon request in a private atomic site.
    ///
    /// - Important: Photon URLs are currently not working for private atomic sites, so this is a workaround
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
    /// - Parameters:
    ///     - url: the url for the media.
    ///     - siteID: the ID of the site that owns this media.
    ///     - provide: the closure that will be called once authentication is sorted out by this class.
    ///         The request can be executed directly without having to do anything else in terms of
    ///         authentication.
    ///     - fail: the closure that will be called upon finding an error condition.
    ///
    private func authenticatedRequestForPrivateAtomicSiteThroughPhoton(
        for url: URL,
        siteID: Int,
        authToken: String,
        onComplete provide: @escaping (URLRequest) -> (),
        onFailure fail: @escaping (Error) -> ()) {

        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            fail(Error.cannotBreakDownURLIntoComponents(url: url))
            return
        }

        guard let wpContentRange = components.path.range(of: "/wp-content") else {
            fail(Error.cannotFindWPContentInPhotonPath(components: components))
            return
        }

        let contentPath = String(components.path[wpContentRange.lowerBound ..< components.path.endIndex])

        components.scheme = secureHttpScheme
        components.host = wpComApiHost
        components.path = "/wpcom/v2/sites/\(siteID)/atomic-auth-proxy/file"
        components.queryItems = [URLQueryItem(name: "path", value: contentPath)]

        guard let finalURL = components.url else {
            fail(Error.cannotCreateAtomicProxyURL(components: components))
            return
        }

        let request = tokenAuthenticatedWPComRequest(for: finalURL, authToken: authToken)
        provide(request)
    }

    // MARK: - Adding the Auth Token

    /// Returns a request with the Bearer token for WPCom authentication.
    ///
    /// - Parameters:
    ///     - url: the url of the media.
    ///     - authToken: the Bearer token to add to the resulting request.
    ///
    private func tokenAuthenticatedWPComRequest(for url: URL, authToken: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        return request
    }
}
