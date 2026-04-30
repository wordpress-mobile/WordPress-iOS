import Foundation
@preconcurrency import WebKit

/// Authentication hook for the OAuth kick-off web view inside
/// `JetpackSocial`. The caller seeds any cookies the wp.com
/// authorize page needs into the web view's cookie store and returns
/// an authenticated `URLRequest` ready to load.
///
/// `WKHTTPCookieStore` is exposed directly because the app's existing
/// `CookieJar` protocol (in `WordPress/Classes/Utility/WebViewController/
/// CookieJar.swift`) already has a `CookieJar` conformance on it — the
/// app-side adapter can pass the store straight through to
/// `RequestAuthenticator.request(url:cookieJar:completion:)` without
/// any wrapping type.
public protocol SocialOAuthAuthenticator: Sendable {
    func authenticatedRequest(
        for url: URL,
        into cookieStore: WKHTTPCookieStore
    ) async -> URLRequest
}
