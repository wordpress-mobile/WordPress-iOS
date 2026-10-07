#if UI_TEST_HTTP_FIXTURES
import Foundation

/// The response a `FixtureSet` answers a request with.
public struct StubResponse: Sendable {
    public let status: Int
    public let headers: [String: String]
    public let body: Data

    /// How long to wait before delivering the response.
    public let delay: TimeInterval

    /// The mapping file the response came from, relative to the `mappings` directory, or `nil`
    /// when no mapping matched the request.
    public let source: String?
}

extension StubResponse {
    /// The response to a request no mapping matches.
    ///
    /// The body has the shape of a WordPress.com error, so the app reports it the way it would
    /// report a real failure.
    static func noFixture(for request: StubRequest) -> StubResponse {
        error(
            status: 404,
            code: "no_fixture",
            message: "No fixture matches \(request.method) \(request.pathAndQuery)",
            source: nil
        )
    }

    static func error(status: Int, code: String, message: String, source: String?) -> StubResponse {
        StubResponse(
            status: status,
            headers: ["Content-Type": "application/json"],
            body: canonicalJSON(["error": code, "message": message]) ?? Data(),
            delay: 0,
            source: source
        )
    }
}

/// A problem with a fixture file.
public struct FixtureError: Error, CustomStringConvertible, Sendable {
    /// The file, relative to the `mappings` directory.
    public let file: String
    public let reason: String

    public var description: String {
        "\(file): \(reason)"
    }
}
#endif
