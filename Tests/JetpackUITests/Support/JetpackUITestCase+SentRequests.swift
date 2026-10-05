import XCTest

extension JetpackUITestCase {
    struct RequestNotSentError: Error, CustomStringConvertible {
        let endpoint: RequestLog.Endpoint
        let timeout: TimeInterval
        let sent: [RequestLog.Request]

        var description: String {
            let sent = sent.map(\.description).joined(separator: "\n")
            return "The app didn't send \(endpoint) within \(timeout) seconds. With that method, it sent:\n\(sent)"
        }
    }

    /// Waits for the app to send a request to an endpoint, and returns the most recent one.
    ///
    /// This is how a test checks that an action reached the server: tap Like, then wait for the
    /// request that likes the post. The request carries the status it was answered with and the
    /// fixture that answered it, so the test can also check that the app got the response it
    /// went on to show.
    ///
    /// The app sends a request some time after the tap that causes it, which is why this waits
    /// rather than reading the log once.
    ///
    /// Only a suite on the fixtures backend can do this: against a real account the app's
    /// requests go to the network, where a test can't see them.
    func waitForRequest(
        _ method: String,
        host: String = "public-api.wordpress.com",
        path: String,
        timeout: TimeInterval = 10
    ) throws -> RequestLog.Request {
        guard let requestLog else {
            throw RequestLogUnavailableError()
        }

        let endpoint = RequestLog.Endpoint(method: method, host: host, path: path)
        let deadline = Date(timeIntervalSinceNow: timeout)
        while true {
            let requests = try requestLog.requests()
            let match = requests.last { $0.method == method && $0.url.host() == host && $0.url.path() == path }
            if let match {
                return match
            }
            guard Date() < deadline else {
                throw RequestNotSentError(
                    endpoint: endpoint,
                    timeout: timeout,
                    sent: requests.filter { $0.method == method }
                )
            }
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.25))
        }
    }
}
