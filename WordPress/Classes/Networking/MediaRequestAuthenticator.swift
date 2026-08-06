import Foundation
import AsyncImageKit
import AVFoundation
import WordPressData

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
struct MediaRequestAuthenticator {
    /// Errors conditions that this class can find.
    ///
    enum Error: Swift.Error {
        case cannotBreakDownURLIntoComponents(url: URL)
        case cannotCreateAtomicURL(components: URLComponents)
        case cannotCreateAtomicProxyURL(components: URLComponents)
        case cannotCreatePrivateURL(components: URLComponents)
        case cannotFindWPContentInPhotonPath(components: URLComponents)
        case failedToLoadAtomicAuthenticationCookies(underlyingError: Swift.Error)
    }

    // MARK: - Request Authentication

    /// Returns an authenticated request for the given URL and the media host.
    @MainActor
    func authenticatedRequest(for url: URL, host: MediaHost) async throws -> URLRequest {
        try await withUnsafeThrowingContinuation { continuation in
            authenticatedRequest(for: url, from: host) { request in
                continuation.resume(returning: request)
            } onFailure: { error in
                continuation.resume(throwing: error)
            }
        }
    }

    /// Pass this method a media URL and host information, and it will handle all the necessary
    /// logic to provide the caller with an authenticated request through the completion closure.
    ///
    /// - Parameters:
    ///     - url: the url for the media.
    ///     - host: the `MediaHost` for the requested Media. This is used for authenticating the requests.
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

        // A private Atomic site serves its media from its own mapped domain, which the
        // WP.com allowlist below rightly refuses to send the account token to. Route those
        // requests through the atomic-auth-proxy instead: the token is only ever attached
        // to public-api.wordpress.com, and WP.com decides whether the viewer can access
        // the file.
        if case .privateAtomicWPComSite(let siteID, _, let authToken, let siteHost) = host,
           let siteHost,
           !url.isWordPressComHost,
           url.host?.lowercased() == siteHost.lowercased(),
           let request = atomicProxyRequest(for: url, siteID: siteID, authToken: authToken) {
            provide(request)
            return
        }

        // We want to make sure we're never sending credentials
        // to a URL that's not safe.
        guard url.isWordPressComHost else {
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
        case .privateAtomicWPComSite(let siteID, let username, let authToken, _):
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

    func authenticatedAsset(for url: URL, host: MediaHost) async throws -> AVURLAsset {
        switch host {
        case .publicSite: AVURLAsset(url: url)
        case .publicWPComSite: AVURLAsset(url: url)
        case .privateSelfHostedSite: AVURLAsset(url: url)
        case .privateWPComSite(let authToken): authenticatedAsset(for: url, authToken: authToken)
        case .privateAtomicWPComSite(_, _, let authToken, _): authenticatedAsset(for: url, authToken: authToken)
        }
    }

    private func authenticatedAsset(for url: URL, authToken: String) -> AVURLAsset {
        guard url.isWordPressComHost else {
            Loggers.networking.warning("Refusing to attach the WP.com token to a non-WP.com host: \(url.host ?? "no host")")
            return AVURLAsset(url: url)
        }

        // Just in case, enforce HTTPs
        var finalURL = url
        if var components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            components.scheme = secureHttpScheme
            finalURL = components.url ?? url
        }

        let headers: [String: String] = ["Authorization": "Bearer \(authToken)"]

        return AVURLAsset(url: finalURL, options: [
            "AVURLAssetHTTPHeaderFieldsKey": headers
        ])
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

        guard let account = try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext) else {
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
    /// atomic private site. If it works then you can remove this workaround logic.
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

        guard let request = atomicProxyRequest(for: url, siteID: siteID, authToken: authToken) else {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                fail(Error.cannotFindWPContentInPhotonPath(components: components))
            } else {
                fail(Error.cannotBreakDownURLIntoComponents(url: url))
            }
            return
        }

        provide(request)
    }

    /// Builds a token-authenticated atomic-auth-proxy request for a media file under the
    /// site's wp-content directory. The token is attached to public-api.wordpress.com only,
    /// never to the original host, so this is safe for URLs on hosts outside the WP.com
    /// allowlist. Returns nil when the URL cannot be proxied (no /wp-content path segment,
    /// or the URL cannot be decomposed).
    private func atomicProxyRequest(for url: URL, siteID: Int, authToken: String) -> URLRequest? {
        guard let sourceComponents = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let wpContentRange = sourceComponents.path.range(of: "/wp-content") else {
            return nil
        }

        let contentPath = String(sourceComponents.path[wpContentRange.lowerBound...])

        // Build the proxy URL from scratch rather than mutating the source URL's
        // components. The source URL is server-supplied and potentially
        // attacker-influenced; reusing its components would carry over authority
        // fields (userinfo, port, fragment) onto the request that attaches the
        // Bearer token. Only the wp-content path is taken from the source.
        var components = URLComponents()
        components.scheme = secureHttpScheme
        components.host = wpComApiHost
        components.path = "/wpcom/v2/sites/\(siteID)/atomic-auth-proxy/file"
        components.queryItems = [URLQueryItem(name: "path", value: contentPath)]

        guard let finalURL = components.url else {
            return nil
        }

        return tokenAuthenticatedWPComRequest(for: finalURL, authToken: authToken)
    }

    // MARK: - Adding the Auth Token

    /// Returns a request with the Bearer token for WPCom authentication.
    ///
    /// - Parameters:
    ///     - url: the url of the media.
    ///     - authToken: the Bearer token to add to the resulting request.
    ///
    private func tokenAuthenticatedWPComRequest(for url: URL, authToken: String) -> URLRequest {
        guard url.isWordPressComHost else {
            Loggers.networking.warning("Refusing to attach the WP.com token to a non-WP.com host: \(url.host ?? "no host")")
            return URLRequest(url: url)
        }

        var request = URLRequest(url: url)
        request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        return request
    }
}
