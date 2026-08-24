import Foundation

extension Blog {

    /// The XML-RPC endpoint URL to use for network requests.
    ///
    /// Older app versions could silently downgrade the discovered XML-RPC endpoint to
    /// http for an https site and persist it, so later XML-RPC traffic and the
    /// credentials it carries crossed plaintext (GHSA-qxpr-7v78-mh5g). For such a site
    /// this returns the https-upgraded endpoint, so a client built from it starts every
    /// request over https. The persisted `xmlrpc` value and the Keychain entry keyed by
    /// it are left untouched (so credential lookups still resolve); only the request
    /// endpoint is upgraded, at the point a client is built. Every credential-bearing
    /// XML-RPC client must be constructed from this, not from the raw `xmlrpc` string.
    ///
    /// This upgrades only the initial endpoint. It does not stop an https-to-http
    /// redirect issued by the server during a request; blocking that in the XML-RPC
    /// client is tracked separately.
    @objc public var xmlrpcURL: URL? {
        guard let xmlrpc, let endpoint = URL(string: xmlrpc) else { return nil }
        // URL schemes are case-insensitive, so compare normalized schemes and rewrite
        // through URL components: an http endpoint (in any spelling) for an https site
        // is upgraded to https; everything else is returned unchanged.
        guard endpoint.scheme?.lowercased() == "http",
            let siteAddress = url, URL(string: siteAddress)?.scheme?.lowercased() == "https",
            var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)
        else {
            return endpoint
        }
        components.scheme = "https"
        return components.url ?? endpoint
    }
}
