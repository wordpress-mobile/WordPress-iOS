import XCTest

extension JetpackUITestCase {
    struct RequestLogUnavailableError: Error, CustomStringConvertible {
        let description = "Only a suite on the fixtures backend can read what the app has sent"
    }

    /// The requests the app has made since it launched for this test that no fixture answered.
    ///
    /// The app got a 404 for each, so whatever asked for it is showing an error or nothing.
    func unansweredRequests() throws -> [RequestLog.Request] {
        guard let requestLog else {
            throw RequestLogUnavailableError()
        }
        return try requestLog.requests().filter { $0.fixture == nil }
    }

    /// How many times the app has requested each endpoint since it launched for this test.
    ///
    /// An endpoint is a method, a host and a path. The query isn't part of it, so requests for
    /// different pages or dates of the same thing count towards one endpoint.
    ///
    /// Only a suite on the fixtures backend can count them: against a real account the app's
    /// requests go to the network, where a test can't see them.
    func requestCounts() throws -> [RequestLog.Endpoint: Int] {
        guard let requestLog else {
            throw RequestLogUnavailableError()
        }
        return try requestLog.requestCounts()
    }

    /// How many times the app has requested one endpoint since it launched for this test.
    func requestCount(
        _ method: String = "GET",
        host: String = "public-api.wordpress.com",
        path: String
    ) throws -> Int {
        try requestCounts()[RequestLog.Endpoint(method: method, host: host, path: path), default: 0]
    }

    /// Fails the test if the app has requested any endpoint more than `limit` times since it
    /// launched, and lists the ones it has.
    ///
    /// - Parameter ignored: Endpoints that are meant to be requested repeatedly, such as the one
    ///   the app sends its analytics events to.
    func assertNoEndpointRequested(
        moreThan limit: Int,
        ignoring ignored: Set<RequestLog.Endpoint> = [],
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let repeated = try requestCounts()
            .filter { $0.value > limit && !ignored.contains($0.key) }
            // The most requested first.
            .sorted { $0.value != $1.value ? $0.value > $1.value : $0.key.description < $1.key.description }
            .map { "\($0.value) × \($0.key)" }
        XCTAssertTrue(
            repeated.isEmpty,
            "Requested more than \(limit) times:\n\(repeated.joined(separator: "\n"))",
            file: file,
            line: line
        )
    }
}
