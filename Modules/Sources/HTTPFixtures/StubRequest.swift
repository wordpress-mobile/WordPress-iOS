import Foundation

/// A request, reduced to the parts a fixture can match on.
public struct StubRequest: Sendable {
    public let method: String
    public let url: URL
    public let body: Data?

    public init(method: String = "GET", url: URL, body: Data? = nil) {
        self.method = method.uppercased()
        self.url = url
        self.body = body
    }
}

extension StubRequest {
    /// The scheme, host and port, such as `https://public-api.wordpress.com`.
    var baseURL: String {
        let port = url.port.map { ":\($0)" } ?? ""
        return "\(url.scheme ?? "https")://\(url.host(percentEncoded: true) ?? "")\(port)"
    }

    /// The path as it was sent, still percent-encoded.
    var path: String {
        let path = url.path(percentEncoded: true)
        return path.isEmpty ? "/" : path
    }

    /// The path and query as they were sent.
    var pathAndQuery: String {
        guard let query = url.query(percentEncoded: true) else {
            return path
        }
        return "\(path)?\(query)"
    }

    var pathSegments: [String] {
        path.split(separator: "/").map(Self.decoded)
    }

    /// The decoded query parameters, in the order they were sent. A name that was sent more than
    /// once appears once per value.
    var queryParameters: [(name: String, value: String)] {
        guard let query = url.query(percentEncoded: true) else {
            return []
        }
        return query.split(separator: "&")
            .map { pair in
                let parts = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
                return (name: Self.decoded(parts[0]), value: parts.count > 1 ? Self.decoded(parts[1]) : "")
            }
    }

    var bodyString: String? {
        body.flatMap { String(data: $0, encoding: .utf8) }
    }

    var bodyJSON: Any? {
        body.flatMap { try? JSONSerialization.jsonObject(with: $0, options: .fragmentsAllowed) }
    }

    private static func decoded(_ component: Substring) -> String {
        let spaced = component.replacingOccurrences(of: "+", with: " ")
        return spaced.removingPercentEncoding ?? spaced
    }
}
