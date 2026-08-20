import Foundation

extension Blog {

    /// The WordPress REST API root URL to use for self-hosted network requests.
    ///
    /// Prefers `restApiRootURL` — the root observed during REST API discovery, which is
    /// served over https for an https site — over a URL derived from the raw `xmlrpc`
    /// string. An older app version could silently downgrade and persist an http `xmlrpc`
    /// endpoint for an https site (GHSA-qxpr-7v78-mh5g), and `url(withPath:)` copies that
    /// scheme verbatim, so a REST client built from it would carry the application password
    /// (sent as a Basic auth header) over plaintext http.
    ///
    /// `restApiRootURL` is written together with the application token (see
    /// `ApplicationPasswordRepository.assign` and `Blog.createRestApiBlog`), so it is always
    /// present when the token is. That makes this a discovery-backed choice rather than a
    /// scheme-rewriting guess: an intentionally-http site is left on http (its discovered
    /// root is http), and an https site uses the https root that discovery observed.
    ///
    /// Falls back to the `xmlrpc`-derived `wp-json/` URL only when no discovered root was
    /// persisted (legacy XML-RPC sign-ins), leaving behavior unchanged for those sites.
    public var selfHostedRestApiRootURL: URL? {
        if let restApiRootURL, let url = URL(string: restApiRootURL) {
            return url
        }
        return url(withPath: "wp-json/").flatMap { URL(string: $0) }
    }
}
